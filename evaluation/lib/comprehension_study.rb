# frozen_string_literal: true

require "digest"
require "fileutils"
require "find"
require "json"
require "open3"
require "tmpdir"
require "time"

module ComprehensionStudy
  ROOT = File.expand_path("..", __dir__)
  CONDITIONS = %w[ordinary post_hoc runtime].freeze
  REVIEW_FIELDS = %w[
    component_model control_data_flow invariants impact_prediction defects review_decision
  ].freeze
  SCORE_FIELDS = (REVIEW_FIELDS + ["evidence_traceability"]).freeze
  ARTIFACT_DEFECTS = %w[
    missing-evidence unsupported-rationale contradicted-current-state stale-history
    semantic-compression reading-order excessive-detail runtime-noise false-confidence-risk
  ].freeze

  module JsonFile
    module_function

    def read(path)
      JSON.parse(File.read(path))
    end

    def write(path, value)
      File.write(path, JSON.pretty_generate(value) + "\n")
    end
  end

  class ProjectFactory
    def prepare(task_id:, destination:)
      task = load_task(task_id)
      raise ArgumentError, "destination already exists" if File.exist?(destination)

      FileUtils.mkdir_p(destination)
      FileUtils.cp_r(File.join(ROOT, "fixtures", "parcel_flow", "."), destination)
      File.write(File.join(destination, "TASK.md"), "# Task\n\n#{task.fetch("prompt")}\n")

      run!("git", "init", "-b", "main", chdir: destination)
      run!("git", "config", "user.email", "study@example.invalid", chdir: destination)
      run!("git", "config", "user.name", "Comprehension Study", chdir: destination)
      run!("git", "add", ".", chdir: destination)
      run!("git", "commit", "-m", "baseline: #{task_id}", chdir: destination)

      {
        "schema_version" => 2,
        "task_id" => task_id,
        "baseline_revision" => run!("git", "rev-parse", "HEAD", chdir: destination).strip
      }
    end

    private

    def load_task(task_id)
      JsonFile.read(File.join(ROOT, "tasks", "#{task_id}.json"))
    rescue Errno::ENOENT
      raise ArgumentError, "unknown task #{task_id.inspect}"
    end

    def run!(*command, chdir:)
      output, error, status = Open3.capture3(*command, chdir: chdir)
      raise "#{command.join(" ")} failed: #{error}" unless status.success?

      output
    end
  end

  class RunImporter
    TEST_COMMAND = ["ruby", "-Ilib", "-Itest", "test/all_test.rb"].freeze
    EXCLUDED_ROOT_ENTRIES = %w[.git .pi .comprehension].freeze

    def import(task_id:, workspace:, ledger:, output:)
      raise ArgumentError, "run output already exists" if File.exist?(output)
      raise ArgumentError, "workspace must be a Git worktree" unless git_worktree?(workspace)

      task = JsonFile.read(File.join(ROOT, "tasks", "#{task_id}.json"))
      task_file = File.join(workspace, "TASK.md")
      raise ArgumentError, "workspace TASK.md is missing" unless File.file?(task_file)

      baseline_revision = capture!("git", "rev-list", "--max-parents=0", "HEAD", chdir: workspace).lines.first&.strip
      raise "workspace has no baseline commit" if baseline_revision.nil? || baseline_revision.empty?
      source_fingerprint = fingerprint(workspace, excluded_root_entries: EXCLUDED_ROOT_ENTRIES)
      FileUtils.mkdir_p(output)
      repository = File.join(output, "repository")
      copy_repository(workspace, repository)
      FileUtils.cp(task_file, File.join(output, "TASK.md"))
      File.write(File.join(output, "diff.patch"), complete_diff(workspace, baseline_revision))
      final_source_fingerprint = fingerprint(workspace, excluded_root_entries: EXCLUDED_ROOT_ENTRIES)
      raise "workspace changed while the evidence cut was being imported" unless source_fingerprint == final_source_fingerprint

      visible_output, visible_error, visible_status = run_visible_tests(repository)
      File.write(File.join(output, "visible-tests.txt"), visible_output + visible_error)
      hidden = HiddenVerifier.new.verify(task_id: task_id, run: output)
      capture = copy_capture_artifacts(ledger, output)

      visible_outcome = visible_status.success? ? "passed" : "failed"
      trial_status = if visible_outcome != "passed"
        "visible-tests-failed"
      elsif capture.fetch("ledger") == "missing"
        "capture-missing"
      else
        "awaiting-guides"
      end

      record = {
        "schema_version" => 2,
        "study_mode" => "pi-import",
        "task_id" => task_id,
        "level" => task.fetch("level"),
        "imported_at" => Time.now.utc.iso8601,
        "baseline_revision" => baseline_revision,
        "final_fingerprint" => fingerprint(repository),
        "visible_tests" => visible_outcome,
        "hidden_tests" => hidden.fetch("outcome"),
        "hidden_test_failures" => hidden.fetch("failures"),
        "capture" => capture,
        "trial_status" => trial_status
      }
      JsonFile.write(File.join(output, "run.json"), record)
      record
    end

    private

    def git_worktree?(workspace)
      _output, _error, status = Open3.capture3("git", "rev-parse", "--is-inside-work-tree", chdir: workspace)
      status.success?
    rescue Errno::ENOENT
      false
    end

    def copy_repository(workspace, destination)
      FileUtils.mkdir_p(destination)
      Dir.children(workspace).sort.each do |entry|
        next if EXCLUDED_ROOT_ENTRIES.include?(entry)

        FileUtils.cp_r(File.join(workspace, entry), destination, preserve: true)
      end
    end

    def copy_capture_artifacts(ledger, output)
      return { "ledger" => "missing", "mental_model" => "missing" } if ledger == "-"
      raise ArgumentError, "ledger does not exist" unless File.file?(ledger)

      research = File.join(output, "research")
      FileUtils.mkdir_p(research)
      FileUtils.cp(ledger, File.join(research, "runtime-events.jsonl"))
      mental_model = File.join(File.dirname(ledger), "mental-model.md")
      if File.file?(mental_model)
        FileUtils.cp(mental_model, File.join(research, "pi-mental-model.md"))
        { "ledger" => "present", "mental_model" => "present" }
      else
        { "ledger" => "present", "mental_model" => "missing" }
      end
    end

    def complete_diff(workspace, baseline_revision)
      diff = capture!(
        "git", "diff", "--binary", baseline_revision, "--", ".", ":(exclude).pi", ":(exclude).comprehension",
        chdir: workspace
      )
      untracked = capture!("git", "ls-files", "--others", "--exclude-standard", chdir: workspace).lines.map(&:strip)
      untracked.reject! { |path| path == ".pi" || path.start_with?(".pi/", ".comprehension/") }
      untracked.sort.each do |path|
        output, error, status = Open3.capture3(
          "git", "diff", "--binary", "--no-index", "--", "/dev/null", path,
          chdir: workspace
        )
        raise "could not diff untracked file #{path}: #{error}" unless [0, 1].include?(status.exitstatus)

        diff << output
      end
      diff
    end

    def run_visible_tests(repository)
      Dir.mktmpdir("comprehension-visible-tests-") do |workspace|
        FileUtils.cp_r(File.join(repository, "."), workspace)
        return Open3.capture3(*TEST_COMMAND, chdir: workspace)
      end
    end

    def fingerprint(repository, excluded_root_entries: [])
      digest = Digest::SHA256.new
      Find.find(repository) do |path|
        next if path == repository

        relative = path.delete_prefix(repository + File::SEPARATOR)
        root_entry = relative.split(File::SEPARATOR, 2).first
        if excluded_root_entries.include?(root_entry)
          Find.prune if File.directory?(path)
          next
        end
        stat = File.lstat(path)
        digest << relative << "\0" << stat.mode.to_s(8) << "\0"
        if stat.symlink?
          digest << File.readlink(path)
        elsif stat.file?
          digest << File.binread(path)
        end
        digest << "\0"
      end
      digest.hexdigest
    end

    def capture!(*command, chdir:)
      output, error, status = Open3.capture3(*command, chdir: chdir)
      raise "#{command.join(" ")} failed: #{error}" unless status.success?

      output
    end
  end

  class HiddenVerifier
    def verify(task_id:, run:)
      hidden_test = File.join(ROOT, "hidden_tests", "#{task_id}_test.rb")
      raise ArgumentError, "unknown hidden test for #{task_id}" unless File.file?(hidden_test)

      output, error, status = Dir.mktmpdir("comprehension-hidden-tests-") do |workspace|
        FileUtils.cp_r(File.join(run, "repository", "."), workspace)
        Open3.capture3("ruby", "-I#{File.join(workspace, "lib")}", hidden_test, chdir: workspace)
      end
      transcript = output + error
      File.write(File.join(run, "hidden-tests.txt"), transcript)
      failures = transcript.scan(/(\d+) failures?/).flatten.map(&:to_i).sum +
        transcript.scan(/(\d+) errors?/).flatten.map(&:to_i).sum
      { "outcome" => status.success? ? "passed" : "failed", "failures" => failures }
    end
  end

  class GuideRegistrar
    MAX_WORDS = 750
    MATCH_TOLERANCE = 0.10

    def attach(run:, post_hoc:, runtime:, current_state:)
      record_path = File.join(run, "run.json")
      record = JsonFile.read(record_path)
      unless record.fetch("trial_status") == "awaiting-guides"
        raise ArgumentError, "run must be awaiting guides"
      end

      inputs = { "post_hoc" => post_hoc, "runtime" => runtime, "current_state" => current_state }
      inputs.each do |name, path|
        raise ArgumentError, "#{name} file does not exist" unless File.file?(path)
      end
      JsonFile.read(current_state)

      post_words = prose_words(post_hoc)
      runtime_words = prose_words(runtime)
      raise ArgumentError, "post-hoc guide exceeds #{MAX_WORDS} words" if post_words > MAX_WORDS
      raise ArgumentError, "runtime guide exceeds #{MAX_WORDS} words" if runtime_words > MAX_WORDS
      longer = [post_words, runtime_words].max
      shorter = [post_words, runtime_words].min
      raise ArgumentError, "guides must not be empty" if shorter.zero?
      raise ArgumentError, "guide lengths differ by more than 10%" if (longer - shorter).fdiv(longer) > MATCH_TOLERANCE
      raise ArgumentError, "guide headings do not match" unless headings(post_hoc) == headings(runtime)

      guides = File.join(run, "guides")
      FileUtils.mkdir_p(File.join(guides, "post_hoc"))
      FileUtils.mkdir_p(File.join(guides, "runtime"))
      FileUtils.cp(post_hoc, File.join(guides, "post_hoc", "review-guide.md"))
      FileUtils.cp(runtime, File.join(guides, "runtime", "review-guide.md"))
      FileUtils.mkdir_p(File.join(run, "research"))
      FileUtils.cp(current_state, File.join(run, "research", "current-state.json"))

      record["guides"] = {
        "post_hoc_words" => post_words,
        "runtime_words" => runtime_words,
        "length_difference_percent" => (((longer - shorter).fdiv(longer)) * 100).round(2)
      }
      record["trial_status"] = "eligible"
      JsonFile.write(record_path, record)
      record
    end

    private

    def prose_words(path)
      File.readlines(path).reject { |line| line.lstrip.start_with?("#") }
        .join.scan(/[[:alnum:]][[:alnum:]'’-]*/).length
    end

    def headings(path)
      File.readlines(path).select { |line| line.start_with?("#") }.map(&:strip)
    end
  end

  class PacketBuilder
    COMMON_MATERIALS = %w[TASK.md diff.patch visible-tests.txt repository].freeze

    def build(run:, destination:, packet_id:, condition:)
      raise ArgumentError, "unknown study condition" unless CONDITIONS.include?(condition)
      raise ArgumentError, "packet destination already exists" if File.exist?(destination)

      record = JsonFile.read(File.join(run, "run.json"))
      raise ArgumentError, "only eligible trials can become review packets" unless record.fetch("trial_status") == "eligible"

      FileUtils.mkdir_p(destination)
      COMMON_MATERIALS.each { |entry| FileUtils.cp_r(File.join(run, entry), destination) }
      if condition != "ordinary"
        source = File.join(run, "guides", condition, "review-guide.md")
        raise ArgumentError, "run has no #{condition} guide" unless File.file?(source)

        FileUtils.cp(source, File.join(destination, "review-guide.md"))
      end
      manifest = {
        "schema_version" => 2,
        "packet_id" => packet_id,
        "task_id" => record.fetch("task_id"),
        "level" => record.fetch("level"),
        "review_instructions" => "Use only this packet and record every file opened through the study CLI."
      }
      JsonFile.write(File.join(destination, "packet.json"), manifest)
      manifest
    end
  end

  class FormativeAssignmentBuilder
    REVIEWER_ID = /\A[a-zA-Z0-9_-]+\z/

    def build(runs:, reviewer:, destination:, seed:)
      raise ArgumentError, "single-reviewer study requires exactly three runs" unless runs.length == CONDITIONS.length
      raise ArgumentError, "invalid reviewer id" unless REVIEWER_ID.match?(reviewer)
      raise ArgumentError, "study destination already exists" if File.exist?(destination)

      conditions = CONDITIONS.shuffle(random: Random.new(seed))
      reviewer_root = File.join(destination, "reviewer")
      packets_root = File.join(reviewer_root, "packets")
      FileUtils.mkdir_p(packets_root)
      assignments = runs.each_with_index.map do |run, index|
        record = JsonFile.read(File.join(run, "run.json"))
        packet_id = format("P%02d", index + 1)
        condition = conditions.fetch(index)
        PacketBuilder.new.build(
          run: run,
          destination: File.join(packets_root, packet_id),
          packet_id: packet_id,
          condition: condition
        )
        {
          "packet_id" => packet_id,
          "reviewer" => reviewer,
          "task_id" => record.fetch("task_id"),
          "level" => record.fetch("level"),
          "condition" => condition,
          "run_path" => File.realpath(run),
          "hidden_tests" => record.fetch("hidden_tests"),
          "hidden_test_failures" => record.fetch("hidden_test_failures")
        }
      end

      public_rows = assignments.shuffle(random: Random.new(seed + 1)).map do |row|
        { "packet_id" => row.fetch("packet_id"), "path" => File.join("packets", row.fetch("packet_id")) }
      end
      JsonFile.write(
        File.join(reviewer_root, "assignment.json"),
        { "schema_version" => 2, "reviewer" => reviewer, "packets" => public_rows }
      )
      key = {
        "schema_version" => 2,
        "study_mode" => "single-reviewer-formative",
        "seed" => seed,
        "assignments" => assignments
      }
      JsonFile.write(File.join(destination, "researcher-key.json"), key)
      key
    end
  end

  class ReviewSession
    MAX_SECONDS = 20 * 60

    def initialize(clock: -> { Time.now.utc })
      @clock = clock
    end

    def start(packet:, reviewer:, destination:)
      raise ArgumentError, "review session already exists" if File.exist?(destination)
      raise ArgumentError, "invalid reviewer id" unless FormativeAssignmentBuilder::REVIEWER_ID.match?(reviewer)

      manifest = JsonFile.read(File.join(packet, "packet.json"))
      state = {
        "schema_version" => 2,
        "packet_id" => manifest.fetch("packet_id"),
        "task_id" => manifest.fetch("task_id"),
        "reviewer" => reviewer,
        "packet_path" => File.realpath(packet),
        "started_at" => @clock.call.iso8601,
        "opened_files" => [],
        "finished_at" => nil
      }
      JsonFile.write(destination, state)
      state
    end

    def open(session_path:, relative_path:)
      state = read_active(session_path)
      packet_root = state.fetch("packet_path")
      resolved = File.realpath(File.join(packet_root, relative_path))
      unless resolved.start_with?(packet_root + File::SEPARATOR) && File.file?(resolved)
        raise ArgumentError, "reviewed path must be a regular file inside the packet"
      end

      normalized = resolved.delete_prefix(packet_root + File::SEPARATOR)
      state.fetch("opened_files") << { "path" => normalized, "opened_at" => @clock.call.iso8601 }
      JsonFile.write(session_path, state)
      File.binread(resolved)
    rescue Errno::ENOENT
      raise ArgumentError, "reviewed file does not exist"
    end

    def finish(session_path:, answers:)
      state = read_active(session_path)
      validate_answers!(answers)
      finished_at = @clock.call
      elapsed = (finished_at - Time.iso8601(state.fetch("started_at"))).round
      state["finished_at"] = finished_at.iso8601
      state["elapsed_seconds"] = elapsed
      state["duration_seconds"] = [elapsed, MAX_SECONDS].min
      state["timed_out"] = elapsed > MAX_SECONDS
      state["unique_opened_files"] = state.fetch("opened_files").map { |entry| entry.fetch("path") }.uniq
      state["answers"] = answers
      JsonFile.write(session_path, state)
      state
    end

    private

    def read_active(path)
      state = JsonFile.read(path)
      raise ArgumentError, "review session is already finished" unless state.fetch("finished_at").nil?

      state
    end

    def validate_answers!(answers)
      REVIEW_FIELDS.each do |field|
        value = answers[field]
        raise ArgumentError, "#{field} must be non-empty text" unless value.is_a?(String) && !value.strip.empty?
      end
      traces = answers["evidence_traces"]
      valid_traces = traces.is_a?(Array) && traces.all? do |trace|
        trace.is_a?(Hash) && trace.keys.sort == %w[claim source] &&
          trace.values.all? { |value| value.is_a?(String) && !value.strip.empty? }
      end
      raise ArgumentError, "evidence_traces must contain claim and source text" unless valid_traces

      confidence = answers["confidence"]
      unless confidence.is_a?(Hash) && confidence.keys.sort == REVIEW_FIELDS.sort &&
          confidence.values.all? { |value| (1..5).cover?(value) }
        raise ArgumentError, "confidence must score every review answer from 1 to 5"
      end
      raise ArgumentError, "cognitive_load must be from 1 to 7" unless (1..7).cover?(answers["cognitive_load"])
    end
  end

  class ResultAnalyzer
    def analyze(researcher_key:, sessions:, scores:, destination:)
      raise ArgumentError, "analysis destination already exists" if File.exist?(destination)

      key = JsonFile.read(researcher_key)
      assignments = key.fetch("assignments")
      session_index = load_index(sessions)
      score_index = load_index(scores)
      observations = assignments.map do |assignment|
        identity = [assignment.fetch("packet_id"), assignment.fetch("reviewer")]
        session = session_index.fetch(identity) { raise ArgumentError, "missing session for #{identity.join("/")}" }
        score = score_index.fetch(identity) { raise ArgumentError, "missing score for #{identity.join("/")}" }
        validate_score!(score)
        observation(assignment, session, score)
      end
      conditions = CONDITIONS.to_h do |condition|
        rows = observations.select { |row| row.fetch("condition") == condition }
        [condition, summarize(rows)]
      end
      result = {
        "schema_version" => 2,
        "study_mode" => "single-reviewer-formative",
        "conditions" => conditions,
        "observations" => observations,
        "decision" => "formative-only",
        "causal_inference" => "not-supported",
        "reason" => "One reviewer and one observation per condition confound task, order, learning, and condition."
      }
      FileUtils.mkdir_p(destination)
      JsonFile.write(File.join(destination, "results.json"), result)
      File.write(File.join(destination, "report.md"), render_report(result))
      result
    end

    private

    def load_index(paths)
      paths.to_h do |path|
        value = JsonFile.read(path)
        [[value.fetch("packet_id"), value.fetch("reviewer")], value]
      end
    end

    def validate_score!(score)
      SCORE_FIELDS.each do |field|
        raise ArgumentError, "#{field} must be an integer from 0 to 2" unless (0..2).cover?(score[field])
      end
      defects = score.fetch("artifact_defects")
      unless defects.is_a?(Array) && defects.all? { |defect| ARTIFACT_DEFECTS.include?(defect) }
        raise ArgumentError, "artifact_defects contains an unknown category"
      end
      raise ArgumentError, "scorer is required" unless score["scorer"].is_a?(String) && !score["scorer"].empty?
    end

    def observation(assignment, session, score)
      task = JsonFile.read(File.join(ROOT, "tasks", "#{assignment.fetch("task_id")}.json"))
      necessary = task.dig("rubric", "necessary_files")
      opened_repository_files = session.fetch("unique_opened_files")
        .select { |path| path.start_with?("repository/") }
        .map { |path| path.delete_prefix("repository/") }
      correctness = REVIEW_FIELDS.sum { |field| score.fetch(field) }.fdiv(REVIEW_FIELDS.length * 2) * 100
      confidence = REVIEW_FIELDS.sum { |field| session.dig("answers", "confidence", field) }
        .fdiv(REVIEW_FIELDS.length)
      confidence_percent = (confidence - 1) * 25
      {
        "packet_id" => assignment.fetch("packet_id"),
        "task_id" => assignment.fetch("task_id"),
        "condition" => assignment.fetch("condition"),
        "duration_seconds" => session.fetch("duration_seconds"),
        "timed_out" => session.fetch("timed_out"),
        "correctness_percent" => correctness.round(2),
        "evidence_traceability_percent" => score.fetch("evidence_traceability") * 50,
        "confidence_calibration_error" => (confidence_percent - correctness).abs.round(2),
        "cognitive_load" => session.dig("answers", "cognitive_load"),
        "files_opened" => session.fetch("unique_opened_files").length,
        "unnecessary_files_opened" => (opened_repository_files - necessary).length,
        "artifact_defects" => score.fetch("artifact_defects")
      }
    end

    def summarize(rows)
      raise ArgumentError, "each condition needs one formative observation" unless rows.length == 1

      row = rows.fetch(0)
      row.slice(
        "task_id", "duration_seconds", "timed_out", "correctness_percent",
        "evidence_traceability_percent", "confidence_calibration_error", "cognitive_load",
        "files_opened", "unnecessary_files_opened", "artifact_defects"
      )
    end

    def render_report(result)
      rows = CONDITIONS.map do |condition|
        summary = result.fetch("conditions").fetch(condition)
        "| #{condition} | #{summary.fetch("task_id")} | #{summary.fetch("duration_seconds")} | " \
          "#{summary.fetch("correctness_percent")} | #{summary.fetch("cognitive_load")} |"
      end.join("\n")
      <<~MARKDOWN
        # Single-reviewer formative result

        Decision: **formative only**

        These observations can reveal workflow problems, confusing artifacts, and useful case evidence. They cannot estimate a treatment effect because task, order, learning, reviewer, and condition are confounded.

        | Condition | Task | Duration (seconds) | Correctness (%) | Cognitive load |
        |---|---|---:|---:|---:|
        #{rows}
      MARKDOWN
    end
  end
end
