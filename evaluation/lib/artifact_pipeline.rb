# frozen_string_literal: true

require "pathname"

module ComprehensionStudy
  module ArtifactContract
    module_function

    CURRENT_SECTIONS = %w[change flow invariants impact validation].freeze
    HISTORY_STATUSES = %w[current historical uncertain].freeze
    FINAL_SOURCES = %w[TASK.md diff.patch visible-tests.txt].freeze
    STEP_NAMES = %w[current_state post_hoc runtime].freeze

    def current_state!(document, task_id:, run:)
      exact_keys!(document, %w[schema_version task_id claims], "current state")
      version!(document)
      raise ArgumentError, "current state task_id does not match the run" unless document["task_id"] == task_id

      claims = claims!(document["claims"], prefix: "cur", max: 20)
      sections = claims.map { |claim| enum!(claim["section"], CURRENT_SECTIONS, "current claim section") }
      missing = CURRENT_SECTIONS - sections
      raise ArgumentError, "current state is missing sections: #{missing.join(', ')}" unless missing.empty?

      claims.each do |claim|
        exact_keys!(claim, %w[id section summary evidence], "current claim")
        evidence!(claim["evidence"], run: run, runtime_ids: nil)
      end
      document
    end

    def history!(document, condition:, task_id:, run:, runtime_ids:)
      exact_keys!(document, %w[schema_version task_id condition claims], "#{condition} history")
      version!(document)
      raise ArgumentError, "#{condition} history task_id does not match the run" unless document["task_id"] == task_id
      raise ArgumentError, "history condition must be #{condition}" unless document["condition"] == condition

      prefix = condition == "post_hoc" ? "post" : "run"
      claims!(document["claims"], prefix: prefix, max: 10, allow_empty: true).each do |claim|
        exact_keys!(claim, %w[id summary status evidence], "#{condition} claim")
        enum!(claim["status"], HISTORY_STATUSES, "history status")
        evidence!(claim["evidence"], run: run, runtime_ids: condition == "runtime" ? runtime_ids : nil)
      end
      document
    end

    def generation!(document)
      exact_keys!(document, %w[schema_version generator steps], "generation metadata")
      version!(document)
      generator = document["generator"]
      exact_keys!(generator, %w[provider model prompt_version settings], "generator")
      %w[provider model prompt_version].each { |key| text!(generator[key], "generator #{key}") }
      raise ArgumentError, "generator prompt_version must be artifact-pipeline-v1" unless generator["prompt_version"] == "artifact-pipeline-v1"
      raise ArgumentError, "generator settings must be an object" unless generator["settings"].is_a?(Hash)
      raise ArgumentError, "unexpected generation steps" unless document["steps"].is_a?(Hash) && document["steps"].keys.sort == STEP_NAMES.sort

      STEP_NAMES.each do |name|
        step = document["steps"].fetch(name)
        exact_keys!(step, %w[input_tokens output_tokens wall_time_ms retries failure_codes], "#{name} generation step")
        %w[input_tokens output_tokens wall_time_ms retries].each { |key| nullable_nonnegative_integer!(step[key], "#{name} #{key}") }
        unless step["failure_codes"].is_a?(Array) && step["failure_codes"].all? { |value| value.is_a?(String) && !value.strip.empty? }
          raise ArgumentError, "#{name} failure_codes must be non-empty strings"
        end
      end
      document
    end

    def audit!(document, claim_ids:)
      exact_keys!(document, %w[schema_version task_id claims instrument], "claim audit")
      version!(document)
      claims = document["claims"]
      raise ArgumentError, "audit claims must be an array" unless claims.is_a?(Array)
      audited_ids = claims.map { |claim| claim.is_a?(Hash) ? claim["claim_id"] : nil }
      raise ArgumentError, "audit must cover every claim exactly once" unless audited_ids.sort == claim_ids.sort && audited_ids.uniq.length == audited_ids.length

      claims.each do |claim|
        exact_keys!(claim, %w[claim_id final_state_support runtime_support recoverability decision_relevance target_outcome severity_if_wrong], "audit claim")
        enum!(claim["final_state_support"], %w[supported contradicted stale not-verifiable], "final_state_support")
        enum!(claim["runtime_support"], %w[observed-transition agent-reported not-present], "runtime_support")
        enum!(claim["recoverability"], %w[post-hoc-recoverable runtime-unique uncertain], "recoverability")
        enum!(claim["decision_relevance"], %w[none contextual review-relevant critical], "decision_relevance")
        enum!(claim["target_outcome"], %w[architecture workflow invariant impact defect review-decision], "target_outcome")
        enum!(claim["severity_if_wrong"], %w[low medium high], "severity_if_wrong")
      end
      instrument!(document["instrument"])
      document
    end

    def canonical_json(value)
      JSON.generate(canonical(value))
    end

    def canonical(value)
      case value
      when Hash then value.keys.sort.to_h { |key| [key, canonical(value.fetch(key))] }
      when Array then value.map { |entry| canonical(entry) }
      else value
      end
    end

    def exact_keys!(value, keys, label)
      raise ArgumentError, "#{label} must be an object" unless value.is_a?(Hash)
      raise ArgumentError, "#{label} has unexpected fields" unless value.keys.sort == keys.sort
    end

    def version!(document)
      raise ArgumentError, "schema_version must be 1" unless document["schema_version"] == 1
    end

    def claims!(claims, prefix:, max:, allow_empty: false)
      unless claims.is_a?(Array) && claims.length <= max && (allow_empty || !claims.empty?)
        raise ArgumentError, "claims must contain #{allow_empty ? 'zero or more' : 'one or more'} entries (maximum #{max})"
      end
      ids = claims.map do |claim|
        raise ArgumentError, "claim must be an object" unless claim.is_a?(Hash)
        id = claim["id"]
        raise ArgumentError, "invalid claim id" unless id.is_a?(String) && /\A#{prefix}-\d{3}\z/.match?(id)
        text!(claim["summary"], "claim summary", max: 500)
        id
      end
      raise ArgumentError, "claim ids must be unique" unless ids.uniq.length == ids.length
      claims
    end

    def evidence!(entries, run:, runtime_ids:)
      unless entries.is_a?(Array) && entries.length.between?(1, 5)
        raise ArgumentError, "claim evidence must contain between one and five entries"
      end
      entries.each do |entry|
        exact_keys!(entry, %w[source locator], "evidence")
        source = text!(entry["source"], "evidence source")
        text!(entry["locator"], "evidence locator", max: 300)
        if source.start_with?("runtime:")
          event_id = source.delete_prefix("runtime:")
          raise ArgumentError, "runtime evidence is not allowed in this artifact" if runtime_ids.nil?
          raise ArgumentError, "unknown runtime event #{event_id.inspect}" unless runtime_ids.include?(event_id)
        else
          validate_final_source!(source, run)
        end
      end
    end

    def validate_final_source!(source, run)
      relative = source.start_with?("repository/") ? source : (FINAL_SOURCES.include?(source) ? source : nil)
      raise ArgumentError, "unsupported evidence source #{source.inspect}" if relative.nil?
      raise ArgumentError, "evidence source cannot traverse directories" if relative.split("/").include?("..") || Pathname.new(relative).absolute?
      root = File.realpath(run)
      resolved = File.expand_path(relative, root)
      real = File.realpath(resolved)
      unless real.start_with?(root + File::SEPARATOR) && File.file?(real)
        raise ArgumentError, "evidence source does not exist: #{source}"
      end
    rescue Errno::ENOENT
      raise ArgumentError, "evidence source does not exist: #{source}"
    end

    def instrument!(instrument)
      keys = %w[duplicate_semantic_event_rate generic_semantic_event_rate capture_failures renderer_failures prohibited_data_findings unaccounted_failures added_tool_calls added_turns capture_tokens capture_wall_time_ms storage_bytes]
      exact_keys!(instrument, keys, "audit instrument")
      %w[duplicate_semantic_event_rate generic_semantic_event_rate].each do |key|
        value = instrument[key]
        raise ArgumentError, "#{key} must be between zero and one" unless value.is_a?(Numeric) && value.between?(0, 1)
      end
      %w[capture_failures renderer_failures prohibited_data_findings unaccounted_failures].each do |key|
        value = instrument[key]
        raise ArgumentError, "#{key} must be an array of strings" unless value.is_a?(Array) && value.all? { |entry| entry.is_a?(String) }
      end
      %w[added_tool_calls added_turns capture_tokens capture_wall_time_ms].each { |key| nullable_nonnegative_integer!(instrument[key], key) }
      nullable_nonnegative_integer!(instrument["storage_bytes"], "storage_bytes", nullable: false)
    end

    def enum!(value, choices, label)
      raise ArgumentError, "invalid #{label}" unless choices.include?(value)
      value
    end

    def text!(value, label, max: 200)
      unless value.is_a?(String) && !value.strip.empty? && value == value.strip && value.length <= max && !value.match?(/[\r\n]/)
        raise ArgumentError, "#{label} must be bounded single-line text"
      end
      value
    end

    def nullable_nonnegative_integer!(value, label, nullable: true)
      return if nullable && value.nil?
      raise ArgumentError, "#{label} must be a non-negative integer" unless value.is_a?(Integer) && value >= 0
    end
  end

  class RuntimeLedger
    def read(path)
      raise ArgumentError, "runtime ledger is missing" unless File.file?(path)
      events = File.readlines(path, chomp: true).reject(&:empty?).map.with_index do |line, index|
        JSON.parse(line)
      rescue JSON::ParserError
        raise ArgumentError, "runtime ledger line #{index + 1} is invalid JSON"
      end
      ids = events.map { |event| event.is_a?(Hash) && event["id"] }
      raise ArgumentError, "every runtime event needs a unique id" if ids.any? { |id| !id.is_a?(String) || id.empty? } || ids.uniq.length != ids.length
      semantic = events.select { |event| event["family"] == "semantic" }
      types = semantic.filter_map { |event| event["type"] }
      superseded_ids = semantic.flat_map { |event| event["supersedes"].is_a?(Array) ? event["supersedes"] : [] }.uniq
      current = semantic.reject do |event|
        %w[refuted superseded].include?(event["status"]) || superseded_ids.include?(event["id"])
      end
      {
        "event_ids" => ids,
        "execution_events" => events.length - semantic.length,
        "semantic_events" => semantic.length,
        "semantic_types" => types.tally.sort.to_h,
        "current_semantic_types" => current.filter_map { |event| event["type"] }.tally.sort.to_h,
        "supersession_links" => semantic.sum { |event| event["supersedes"].is_a?(Array) ? event["supersedes"].length : 0 }
      }
    end
  end

  class GuideRenderer
    HEADINGS = {
      "change" => "Change and responsibilities",
      "flow" => "Control and data flow",
      "invariants" => "Constraints and invariants",
      "impact" => "Impact and likely modification points",
      "validation" => "Validation and unresolved risks"
    }.freeze

    def render(current:, history:)
      sections = ["# Review Guide", ""]
      HEADINGS.each do |key, heading|
        sections << "## #{heading}" << ""
        current.fetch("claims").select { |claim| claim.fetch("section") == key }.each do |claim|
          sections << bullet(claim)
        end
        sections << ""
      end
      sections << "## Decisions, revisions, and rejected paths" << ""
      if history.fetch("claims").empty?
        sections << "No additional history claims were recorded."
      else
        history.fetch("claims").each { |claim| sections << bullet(claim, status: claim.fetch("status")) }
      end
      sections.join("\n").rstrip + "\n"
    end

    def validate_pair!(current:, post_hoc:, runtime:)
      counts = [prose_word_count(current, post_hoc), prose_word_count(current, runtime)]
      raise ArgumentError, "guide exceeds the 750-word limit" if counts.any? { |count| count > 750 }
      larger = counts.max
      raise ArgumentError, "guide lengths differ by more than 10%" if larger.positive? && (counts.max - counts.min).fdiv(larger) > 0.10
      counts
    end

    private

    def bullet(claim, status: nil)
      citations = claim.fetch("evidence").map { |entry| "#{entry.fetch('source')} (#{entry.fetch('locator')})" }.join("; ")
      marker = status ? " [#{status}]" : ""
      "- **#{claim.fetch('id')}#{marker}:** #{claim.fetch('summary')} _Evidence: #{citations}_"
    end

    def prose_word_count(current, history)
      summaries = current.fetch("claims").map { |claim| claim.fetch("summary") }
      if history.fetch("claims").empty?
        summaries << "No additional history claims were recorded."
      else
        summaries.concat(history.fetch("claims").map { |claim| claim.fetch("summary") })
      end
      summaries.join(" ").scan(/[\p{L}\p{N}][\p{L}\p{N}_'-]*/).length
    end
  end

  class ArtifactIntegrity
    def verify(run)
      root = File.join(run, "research", "artifacts")
      documents = {
        "current-state.json" => JsonFile.read(File.join(root, "current-state.json")),
        "post-hoc-history.json" => JsonFile.read(File.join(root, "post-hoc-history.json")),
        "runtime-history.json" => JsonFile.read(File.join(root, "runtime-history.json"))
      }
      generation = JsonFile.read(File.join(root, "generation-metadata.json"))
      manifest = JsonFile.read(File.join(root, "generation-manifest.json"))
      expected_artifacts = documents.transform_values do |value|
        Digest::SHA256.hexdigest(ArtifactContract.canonical_json(value))
      end
      sources = documents.values.flat_map do |document|
        document.fetch("claims").flat_map { |claim| claim.fetch("evidence").map { |entry| entry.fetch("source") } }
      end.reject { |source| source.start_with?("runtime:") }
      evidence_hashes = (%w[TASK.md diff.patch visible-tests.txt] + sources).uniq.sort.to_h do |name|
        ArtifactContract.validate_final_source!(name, run)
        [name, Digest::SHA256.file(File.join(run, name)).hexdigest]
      end
      ledger = RuntimeLedger.new.read(File.join(run, "research", "runtime-events.jsonl"))
      prompt_root = File.join(ROOT, "prompts")
      prompt_hashes = ArtifactPipeline::PROMPTS.transform_values do |name|
        Digest::SHA256.file(File.join(prompt_root, name)).hexdigest
      end
      renderer = GuideRenderer.new
      current = documents.fetch("current-state.json")
      post = documents.fetch("post-hoc-history.json")
      runtime = documents.fetch("runtime-history.json")
      word_counts = renderer.validate_pair!(current: current, post_hoc: post, runtime: runtime)
      guides_match = {
        "post_hoc" => post,
        "runtime" => runtime
      }.all? do |condition, history|
        expected = renderer.render(current: current, history: history)
        File.binread(File.join(run, "guides", condition, "review-guide.md")) == expected
      end

      guides_match &&
        manifest.fetch("artifact_hashes") == expected_artifacts &&
        manifest.fetch("evidence_hashes") == evidence_hashes &&
        manifest.fetch("final_evidence_hash") == Digest::SHA256.hexdigest(ArtifactContract.canonical_json(evidence_hashes)) &&
        manifest.fetch("ledger_hash") == Digest::SHA256.file(File.join(run, "research", "runtime-events.jsonl")).hexdigest &&
        manifest.fetch("prompt_hashes") == prompt_hashes &&
        manifest.fetch("runtime_summary") == ledger.reject { |key, _| key == "event_ids" } &&
        manifest.fetch("guide_word_counts") == { "post_hoc" => word_counts[0], "runtime" => word_counts[1] } &&
        manifest.fetch("generation") == generation
    rescue StandardError
      false
    end
  end

  class ClaimAuditIntegrity
    def verify(run, record)
      root = File.join(run, "research", "artifacts")
      audit = JsonFile.read(File.join(root, "claim-audit.json"))
      documents = %w[current-state.json post-hoc-history.json runtime-history.json].map do |name|
        JsonFile.read(File.join(root, name))
      end
      claim_ids = documents.flat_map { |document| document.fetch("claims").map { |claim| claim.fetch("id") } }
      raise ArgumentError, "audit task_id does not match the run" unless audit["task_id"] == record.fetch("task_id")
      ArtifactContract.audit!(audit, claim_ids: claim_ids)
      expected = record.fetch("claim_audit").fetch("sha256")
      expected == Digest::SHA256.hexdigest(ArtifactContract.canonical_json(audit))
    rescue StandardError
      false
    end
  end

  class ArtifactPipeline
    PROMPTS = {
      "current_state" => "current-state-v1.md",
      "post_hoc" => "post-hoc-history-v1.md",
      "runtime" => "runtime-history-v1.md",
      "audit" => "audit-v1.md"
    }.freeze

    def register(run:, current_state:, post_hoc:, runtime:, generation:)
      record = JsonFile.read(File.join(run, "run.json"))
      raise ArgumentError, "run is not awaiting guides" unless record.fetch("trial_status") == "awaiting-guides"
      raise ArgumentError, "run already has generated artifacts" if File.exist?(File.join(run, "guides")) || File.exist?(File.join(run, "research", "artifacts"))

      ledger_path = File.join(run, "research", "runtime-events.jsonl")
      ledger = RuntimeLedger.new.read(ledger_path)
      current = JsonFile.read(current_state)
      post = JsonFile.read(post_hoc)
      run_history = JsonFile.read(runtime)
      generation_data = JsonFile.read(generation)
      task_id = record.fetch("task_id")
      ArtifactContract.current_state!(current, task_id: task_id, run: run)
      ArtifactContract.history!(post, condition: "post_hoc", task_id: task_id, run: run, runtime_ids: ledger.fetch("event_ids"))
      ArtifactContract.history!(run_history, condition: "runtime", task_id: task_id, run: run, runtime_ids: ledger.fetch("event_ids"))
      ArtifactContract.generation!(generation_data)

      renderer = GuideRenderer.new
      guides = {
        "post_hoc" => renderer.render(current: current, history: post),
        "runtime" => renderer.render(current: current, history: run_history)
      }
      word_counts = renderer.validate_pair!(current: current, post_hoc: post, runtime: run_history)
      documents = { "current-state.json" => current, "post-hoc-history.json" => post, "runtime-history.json" => run_history }
      manifest = manifest_for(run, documents, generation_data, ledger, word_counts)

      artifacts = File.join(run, "research", "artifacts")
      FileUtils.mkdir_p(artifacts)
      documents.each { |name, value| JsonFile.write(File.join(artifacts, name), value) }
      JsonFile.write(File.join(artifacts, "generation-metadata.json"), generation_data)
      JsonFile.write(File.join(artifacts, "generation-manifest.json"), manifest)
      guides.each do |condition, content|
        destination = File.join(run, "guides", condition)
        FileUtils.mkdir_p(destination)
        File.write(File.join(destination, "review-guide.md"), content)
      end
      record["trial_status"] = "awaiting-audit"
      record["artifact_pipeline"] = { "schema_version" => 1, "manifest" => "research/artifacts/generation-manifest.json" }
      JsonFile.write(File.join(run, "run.json"), record)
      record
    end

    private

    def manifest_for(run, documents, generation, ledger, word_counts)
      prompt_root = File.join(ROOT, "prompts")
      cited_sources = documents.values.flat_map do |document|
        document.fetch("claims").flat_map { |claim| claim.fetch("evidence").map { |entry| entry.fetch("source") } }
      end.reject { |source| source.start_with?("runtime:") }
      evidence_sources = (%w[TASK.md diff.patch visible-tests.txt] + cited_sources).uniq.sort
      evidence_hashes = evidence_sources.to_h do |name|
        [name, Digest::SHA256.file(File.join(run, name)).hexdigest]
      end
      {
        "schema_version" => 1,
        "artifact_hashes" => documents.transform_values { |value| Digest::SHA256.hexdigest(ArtifactContract.canonical_json(value)) },
        "evidence_hashes" => evidence_hashes,
        "final_evidence_hash" => Digest::SHA256.hexdigest(ArtifactContract.canonical_json(evidence_hashes)),
        "ledger_hash" => Digest::SHA256.file(File.join(run, "research", "runtime-events.jsonl")).hexdigest,
        "prompt_hashes" => PROMPTS.transform_values { |name| Digest::SHA256.file(File.join(prompt_root, name)).hexdigest },
        "runtime_summary" => ledger.reject { |key, _| key == "event_ids" },
        "guide_word_counts" => { "post_hoc" => word_counts[0], "runtime" => word_counts[1] },
        "generation" => generation
      }
    end
  end

  class ClaimAuditor
    def register(run:, audit:)
      record = JsonFile.read(File.join(run, "run.json"))
      raise ArgumentError, "run is not awaiting audit" unless record.fetch("trial_status") == "awaiting-audit"
      raise ArgumentError, "registered artifacts failed their integrity check" unless ArtifactIntegrity.new.verify(run)
      artifact_root = File.join(run, "research", "artifacts")
      documents = %w[current-state.json post-hoc-history.json runtime-history.json].map { |name| JsonFile.read(File.join(artifact_root, name)) }
      ids = documents.flat_map { |document| document.fetch("claims").map { |claim| claim.fetch("id") } }
      raise ArgumentError, "claim ids must be unique across all artifacts" unless ids.uniq.length == ids.length
      audit_data = JsonFile.read(audit)
      raise ArgumentError, "audit task_id does not match the run" unless audit_data["task_id"] == record.fetch("task_id")
      ArtifactContract.audit!(audit_data, claim_ids: ids)
      JsonFile.write(File.join(artifact_root, "claim-audit.json"), audit_data)
      record["trial_status"] = "audit-complete"
      record["claim_audit"] = {
        "schema_version" => 1,
        "sha256" => Digest::SHA256.hexdigest(ArtifactContract.canonical_json(audit_data))
      }
      JsonFile.write(File.join(run, "run.json"), record)
      record
    end
  end

  class FormativeGate
    REQUIRED_LEVELS = %w[small medium non-trivial].freeze

    def evaluate(runs:, destination:)
      raise ArgumentError, "gate requires exactly three runs" unless runs.length == 3
      raise ArgumentError, "gate report already exists" if File.exist?(destination)
      records = runs.map { |run| JsonFile.read(File.join(run, "run.json")) }
      raise ArgumentError, "gate requires one small, medium, and non-trivial run" unless records.map { |record| record.fetch("level") }.sort == REQUIRED_LEVELS.sort
      raise ArgumentError, "all runs must have completed audits" unless records.all? { |record| record.fetch("trial_status") == "audit-complete" }

      results = runs.zip(records).map { |run, record| evaluate_run(run, record) }
      passed = results.all? { |result| result.fetch("passed") }
      report = { "schema_version" => 1, "gate" => "artifact-pipeline-v1", "passed" => passed, "runs" => results }
      JsonFile.write(destination, report)
      runs.zip(records).each do |run, record|
        record["trial_status"] = passed ? "eligible" : "gate-failed"
        record["artifact_gate"] = { "schema_version" => 1, "passed" => passed, "report" => File.expand_path(destination) }
        JsonFile.write(File.join(run, "run.json"), record)
      end
      report
    end

    private

    def evaluate_run(run, record)
      root = File.join(run, "research", "artifacts")
      audit = JsonFile.read(File.join(root, "claim-audit.json"))
      manifest = JsonFile.read(File.join(root, "generation-manifest.json"))
      claims = audit.fetch("claims")
      instrument = audit.fetch("instrument")
      current_ids = JsonFile.read(File.join(root, "current-state.json")).fetch("claims").map { |claim| claim.fetch("id") }
      current_audits = claims.select { |claim| current_ids.include?(claim.fetch("claim_id")) }
      stale_rate = current_audits.count { |claim| %w[contradicted stale].include?(claim.fetch("final_state_support")) }.fdiv(current_audits.length)
      checks = {
        "artifact_integrity" => ArtifactIntegrity.new.verify(run),
        "claim_audit_integrity" => ClaimAuditIntegrity.new.verify(run, record),
        "current_state_error_rate_below_5_percent" => stale_rate < 0.05,
        "no_high_severity_contradictions" => claims.none? { |claim| claim.fetch("severity_if_wrong") == "high" && claim.fetch("final_state_support") == "contradicted" },
        "no_pipeline_or_privacy_failures" => %w[capture_failures renderer_failures prohibited_data_findings unaccounted_failures].all? { |key| instrument.fetch(key).empty? },
        "matched_guides_within_budget" => manifest.fetch("guide_word_counts").values.all? { |count| count <= 750 }
      }
      unless record.fetch("level") == "small"
        checks["runtime_unique_relevant_claim"] = claims.any? do |claim|
          claim.fetch("claim_id").start_with?("run-") && claim.fetch("recoverability") == "runtime-unique" &&
            %w[review-relevant critical].include?(claim.fetch("decision_relevance"))
        end
        semantic_types = manifest.fetch("runtime_summary").fetch("current_semantic_types").keys
        checks["required_semantic_coverage"] = %w[goal decision validation].all? { |type| semantic_types.include?(type) } &&
          semantic_types.any? { |type| %w[constraint invariant].include?(type) }
      end
      { "task_id" => record.fetch("task_id"), "level" => record.fetch("level"), "passed" => checks.values.all?, "checks" => checks }
    end
  end

  class DiagnosticGate
    EXPECTED_TASK = "nontrivial-idempotent-dispatch"
    REQUIRED_PROMPTS = {
      "implementation" => "trajectory-positive-control-v1",
      "closure" => "closure-v2"
    }.freeze

    def evaluate(run:, registration:, destination:)
      raise ArgumentError, "diagnostic report already exists" if File.exist?(destination)
      record = JsonFile.read(File.join(run, "run.json"))
      raise ArgumentError, "diagnostic requires a completed claim audit" unless record.fetch("trial_status") == "audit-complete"
      raise ArgumentError, "diagnostic may only be registered once" if record.key?("diagnostic_gate")
      data = JsonFile.read(registration)
      validate_registration!(data, record)

      events = File.readlines(File.join(run, "research", "runtime-events.jsonl"), chomp: true)
        .reject(&:empty?).map { |line| JSON.parse(line) }
      semantic = events.select { |event| event["family"] == "semantic" }
      by_id = semantic.to_h { |event| [event.fetch("id"), event] }
      audit = JsonFile.read(File.join(run, "research", "artifacts", "claim-audit.json"))
      runtime = JsonFile.read(File.join(run, "research", "artifacts", "runtime-history.json"))

      closure = data.fetch("closure")
      closure_events = closure.fetch("event_ids").filter_map { |id| by_id[id] }
      current_types = current_semantic_types(semantic)
      gate_a_checks = {
        "artifact_integrity" => ArtifactIntegrity.new.verify(run),
        "claim_audit_integrity" => ClaimAuditIntegrity.new.verify(run, record),
        "closure_attempted" => closure.fetch("attempted"),
        "closure_did_not_modify_source" => !closure.fetch("source_modified"),
        "closure_claims_supported_by_final_state" => closure.fetch("final_state_support") == "supported",
        "no_closure_failures" => closure.fetch("failure_codes").empty?,
        "closure_event_ids_exist" => closure_events.length == closure.fetch("event_ids").length,
        "required_semantic_coverage" => %w[goal decision validation].all? { |type| current_types.include?(type) } &&
          current_types.any? { |type| %w[constraint invariant].include?(type) },
        "no_pipeline_or_privacy_failures" => no_pipeline_or_privacy_failures?(audit)
      }

      control = data.fetch("positive_control")
      hypothesis = by_id[control.fetch("initial_hypothesis_event_id")]
      failure = by_id[control.fetch("failure_event_id")]
      revision = by_id[control.fetch("revision_event_id")]
      ordered = [hypothesis, failure, revision].all? &&
        [hypothesis, failure, revision].map { |event| semantic.index(event) }.each_cons(2).all? { |left, right| left < right }
      superseded = revision && Array(revision["supersedes"]).include?(control.fetch("initial_hypothesis_event_id"))
      trajectory_ids = control.values_at("initial_hypothesis_event_id", "failure_event_id", "revision_event_id")
      runtime_claim_ids = runtime.fetch("claims").filter_map do |claim|
        sources = claim.fetch("evidence").map { |entry| entry.fetch("source") }
        claim.fetch("id") if trajectory_ids.all? { |id| sources.include?("runtime:#{id}") }
      end
      runtime_unique = audit.fetch("claims").any? do |claim|
        runtime_claim_ids.include?(claim.fetch("claim_id")) && claim.fetch("recoverability") == "runtime-unique" &&
          %w[review-relevant critical].include?(claim.fetch("decision_relevance"))
      end
      gate_b_checks = {
        "initial_attempt_is_hypothesis" => hypothesis&.fetch("type", nil) == "hypothesis",
        "expected_cross_instance_test_failed" => control.fetch("expected_test_failed") && failure&.fetch("type", nil) == "failure",
        "revision_follows_failure" => ordered && revision&.fetch("type", nil) == "revision",
        "revision_supersedes_initial_hypothesis" => superseded,
        "runtime_claim_cites_complete_trajectory" => !runtime_claim_ids.empty?,
        "runtime_unique_relevant_claim" => runtime_unique,
        "final_visible_tests_passed" => control.fetch("final_visible_tests_passed") && record.fetch("visible_tests") == "passed"
      }

      report = {
        "schema_version" => 1,
        "gate" => "instrument-v2-diagnostic",
        "artificial_positive_control" => true,
        "task_id" => record.fetch("task_id"),
        "gate_a" => { "passed" => gate_a_checks.values.all?, "checks" => gate_a_checks },
        "gate_b" => { "passed" => gate_b_checks.values.all?, "checks" => gate_b_checks }
      }
      report["passed"] = report.dig("gate_a", "passed") && report.dig("gate_b", "passed")
      JsonFile.write(destination, report)
      record["diagnostic_gate"] = {
        "schema_version" => 1,
        "passed" => report.fetch("passed"),
        "report" => File.expand_path(destination),
        "reviewer_eligible" => false
      }
      JsonFile.write(File.join(run, "run.json"), record)
      report
    end

    private

    def validate_registration!(data, record)
      ArtifactContract.exact_keys!(
        data,
        %w[schema_version instrument_version task_id artificial_positive_control prompt_versions closure positive_control],
        "diagnostic registration"
      )
      raise ArgumentError, "diagnostic schema_version must be 1" unless data["schema_version"] == 1
      raise ArgumentError, "instrument_version must be instrument-v2" unless data["instrument_version"] == "instrument-v2"
      raise ArgumentError, "diagnostic task must be #{EXPECTED_TASK}" unless data["task_id"] == EXPECTED_TASK && record["task_id"] == EXPECTED_TASK
      raise ArgumentError, "diagnostic must be marked as an artificial positive control" unless data["artificial_positive_control"] == true
      ArtifactContract.exact_keys!(data["prompt_versions"], REQUIRED_PROMPTS.keys, "diagnostic prompt versions")
      raise ArgumentError, "unexpected diagnostic prompt versions" unless data["prompt_versions"] == REQUIRED_PROMPTS
      ArtifactContract.exact_keys!(
        data["closure"],
        %w[attempted event_ids source_modified final_state_support failure_codes],
        "diagnostic closure"
      )
      ArtifactContract.exact_keys!(
        data["positive_control"],
        %w[initial_hypothesis_event_id failure_event_id revision_event_id expected_test_failed final_visible_tests_passed],
        "diagnostic positive control"
      )
      closure = data["closure"]
      raise ArgumentError, "closure event_ids must be unique strings" unless string_array?(closure["event_ids"]) && closure["event_ids"].uniq.length == closure["event_ids"].length
      raise ArgumentError, "closure failure_codes must be strings" unless string_array?(closure["failure_codes"], allow_empty: true)
      raise ArgumentError, "closure final_state_support must be supported or unsupported" unless %w[supported unsupported].include?(closure["final_state_support"])
      %w[attempted source_modified].each { |key| raise ArgumentError, "closure #{key} must be boolean" unless [true, false].include?(closure[key]) }
      control = data["positive_control"]
      %w[initial_hypothesis_event_id failure_event_id revision_event_id].each do |key|
        raise ArgumentError, "#{key} must be a non-empty string" unless control[key].is_a?(String) && !control[key].empty?
      end
      %w[expected_test_failed final_visible_tests_passed].each do |key|
        raise ArgumentError, "#{key} must be boolean" unless [true, false].include?(control[key])
      end
    end

    def string_array?(value, allow_empty: false)
      value.is_a?(Array) && (allow_empty || !value.empty?) && value.all? { |entry| entry.is_a?(String) && !entry.empty? }
    end

    def current_semantic_types(events)
      superseded = events.flat_map { |event| Array(event["supersedes"]) }
      events.reject { |event| %w[refuted superseded].include?(event["status"]) || superseded.include?(event["id"]) }
        .filter_map { |event| event["type"] }.uniq
    end

    def no_pipeline_or_privacy_failures?(audit)
      instrument = audit.fetch("instrument")
      %w[capture_failures renderer_failures prohibited_data_findings unaccounted_failures].all? do |key|
        instrument.fetch(key).empty?
      end
    end
  end

  class NaturalTaskGate
    TASKS = {
      1 => "medium-normalized-item-validation",
      2 => "nontrivial-dispatch-log-rollback"
    }.freeze
    REQUIRED_PROMPTS = {
      "implementation" => "natural-implementation-v1",
      "closure" => "closure-v2"
    }.freeze

    def evaluate(run:, registration:, destination:)
      raise ArgumentError, "natural gate report already exists" if File.exist?(destination)
      record = JsonFile.read(File.join(run, "run.json"))
      raise ArgumentError, "natural gate requires a completed claim audit" unless record.fetch("trial_status") == "audit-complete"
      raise ArgumentError, "natural gate may only be registered once" if record.key?("natural_gate")
      data = JsonFile.read(registration)
      validate_registration!(data, record)

      events = File.readlines(File.join(run, "research", "runtime-events.jsonl"), chomp: true)
        .reject(&:empty?).map { |line| JSON.parse(line) }
      by_id = events.to_h { |event| [event.fetch("id"), event] }
      semantic = events.select { |event| event["family"] == "semantic" }
      audit = JsonFile.read(File.join(run, "research", "artifacts", "claim-audit.json"))
      manifest = JsonFile.read(File.join(run, "research", "artifacts", "generation-manifest.json"))
      runtime = JsonFile.read(File.join(run, "research", "artifacts", "runtime-history.json"))
      current_ids = JsonFile.read(File.join(run, "research", "artifacts", "current-state.json"))
        .fetch("claims").map { |claim| claim.fetch("id") }
      current_audits = audit.fetch("claims").select { |claim| current_ids.include?(claim.fetch("claim_id")) }
      stale_rate = current_audits.count { |claim| %w[contradicted stale].include?(claim.fetch("final_state_support")) }.fdiv(current_audits.length)

      closure = data.fetch("closure")
      closure_start = by_id[closure.fetch("start_event_id")]
      closure_events = closure.fetch("event_ids").filter_map { |id| by_id[id] }
      current_types = current_semantic_types(semantic)
      instrument = audit.fetch("instrument")
      validity_checks = {
        "artifact_integrity" => ArtifactIntegrity.new.verify(run),
        "claim_audit_integrity" => ClaimAuditIntegrity.new.verify(run, record),
        "visible_tests_passed" => record.fetch("visible_tests") == "passed",
        "closure_attempted" => closure.fetch("attempted"),
        "closure_start_exists" => !!(closure_start&.fetch("family", nil) == "execution" && closure_start&.fetch("type", nil) == "session_started"),
        "closure_did_not_modify_source" => !closure.fetch("source_modified"),
        "closure_claims_supported_by_final_state" => closure.fetch("final_state_support") == "supported",
        "no_closure_failures" => closure.fetch("failure_codes").empty?,
        "closure_event_ids_exist" => closure_events.length == closure.fetch("event_ids").length,
        "required_semantic_coverage" => %w[goal decision validation].all? { |type| current_types.include?(type) } &&
          current_types.any? { |type| %w[constraint invariant].include?(type) },
        "current_state_error_rate_below_5_percent" => stale_rate < 0.05,
        "no_high_severity_contradictions" => audit.fetch("claims").none? do |claim|
          claim.fetch("severity_if_wrong") == "high" && claim.fetch("final_state_support") == "contradicted"
        end,
        "no_pipeline_or_privacy_failures" => %w[capture_failures renderer_failures prohibited_data_findings unaccounted_failures]
          .all? { |key| instrument.fetch(key).empty? },
        "matched_guides_within_budget" => manifest.fetch("guide_word_counts").values.all? { |count| count <= 750 }
      }

      sequence = data.fetch("natural_sequence")
      sequence_events = sequence.fetch("event_ids").filter_map { |id| by_id[id] }
      boundary_index = closure_start && events.index(closure_start)
      pre_closure = boundary_index && sequence_events.length == sequence.fetch("event_ids").length &&
        sequence_events.all? { |event| events.index(event) < boundary_index }
      ordered_semantic = sequence_events.select { |event| event["family"] == "semantic" }.sort_by { |event| events.index(event) }
      causal_pair = ordered_semantic.each_with_index.any? do |origin, index|
        next false unless %w[hypothesis alternative failure].include?(origin["type"])

        ordered_semantic.drop(index + 1).any? do |later|
          %w[decision revision].include?(later["type"]) &&
            (Array(later["supersedes"]).include?(origin["id"]) || !Array(later["because"]).empty?)
        end
      end
      runtime_claim = runtime.fetch("claims").find { |claim| claim["id"] == sequence["claim_id"] }
      cited_ids = runtime_claim&.fetch("evidence", [])&.filter_map do |entry|
        entry.fetch("source").delete_prefix("runtime:") if entry.fetch("source").start_with?("runtime:")
      end || []
      audit_row = audit.fetch("claims").find { |claim| claim["claim_id"] == sequence["claim_id"] }
      increment_checks = {
        "natural_sequence_registered" => sequence["claim_id"].is_a?(String) && sequence.fetch("event_ids").length >= 2,
        "sequence_events_exist" => sequence_events.length == sequence.fetch("event_ids").length,
        "sequence_precedes_closure" => !!pre_closure,
        "causal_sequence_present" => causal_pair,
        "runtime_claim_cites_sequence" => !!(runtime_claim && sequence.fetch("event_ids").all? { |id| cited_ids.include?(id) }),
        "runtime_unique_relevant_claim" => !!(audit_row && audit_row.fetch("recoverability") == "runtime-unique" &&
          %w[review-relevant critical].include?(audit_row.fetch("decision_relevance"))),
        "not_equivalently_supported_by_final_state" => !!(audit_row && audit_row.fetch("final_state_support") == "not-verifiable")
      }

      valid = validity_checks.values.all?
      increment = increment_checks.values.all?
      decision = if !valid
        "inconclusive"
      elsif !increment
        "pivot-post-hoc"
      elsif data.fetch("phase") == 1
        "continue"
      else
        "reviewer-study-ready"
      end
      report = {
        "schema_version" => 1,
        "gate" => "natural-task-v2",
        "task_id" => record.fetch("task_id"),
        "phase" => data.fetch("phase"),
        "valid" => valid,
        "runtime_increment" => increment,
        "passed" => valid && increment,
        "decision" => decision,
        "validity_checks" => validity_checks,
        "increment_checks" => increment_checks,
        "hidden_tests" => "researcher-only, non-gating"
      }
      JsonFile.write(destination, report)
      record["natural_gate"] = {
        "schema_version" => 1,
        "passed" => report.fetch("passed"),
        "decision" => decision,
        "report" => File.expand_path(destination),
        "reviewer_eligible" => false
      }
      JsonFile.write(File.join(run, "run.json"), record)
      report
    end

    private

    def validate_registration!(data, record)
      ArtifactContract.exact_keys!(
        data,
        %w[schema_version instrument_version task_id phase prior_gate_report prompt_versions closure natural_sequence],
        "natural gate registration"
      )
      raise ArgumentError, "natural gate schema_version must be 1" unless data["schema_version"] == 1
      raise ArgumentError, "instrument_version must be instrument-v2" unless data["instrument_version"] == "instrument-v2"
      phase = data["phase"]
      raise ArgumentError, "natural gate phase must be 1 or 2" unless TASKS.key?(phase)
      expected_task = TASKS.fetch(phase)
      raise ArgumentError, "unexpected task for natural gate phase" unless data["task_id"] == expected_task && record["task_id"] == expected_task
      validate_prior_gate!(phase, data["prior_gate_report"])
      ArtifactContract.exact_keys!(data["prompt_versions"], REQUIRED_PROMPTS.keys, "natural gate prompt versions")
      raise ArgumentError, "unexpected natural gate prompt versions" unless data["prompt_versions"] == REQUIRED_PROMPTS
      ArtifactContract.exact_keys!(
        data["closure"],
        %w[attempted start_event_id event_ids source_modified final_state_support failure_codes],
        "natural gate closure"
      )
      ArtifactContract.exact_keys!(data["natural_sequence"], %w[claim_id event_ids], "natural causal sequence")
      closure = data["closure"]
      %w[start_event_id].each { |key| require_text!(closure[key], key) }
      raise ArgumentError, "closure event_ids must be unique strings" unless string_array?(closure["event_ids"]) && closure["event_ids"].uniq.length == closure["event_ids"].length
      raise ArgumentError, "closure failure_codes must be strings" unless string_array?(closure["failure_codes"], allow_empty: true)
      raise ArgumentError, "closure final_state_support must be supported or unsupported" unless %w[supported unsupported].include?(closure["final_state_support"])
      %w[attempted source_modified].each { |key| raise ArgumentError, "closure #{key} must be boolean" unless [true, false].include?(closure[key]) }
      sequence = data["natural_sequence"]
      unless sequence["claim_id"].nil? || (sequence["claim_id"].is_a?(String) && !sequence["claim_id"].empty?)
        raise ArgumentError, "natural sequence claim_id must be null or a non-empty string"
      end
      raise ArgumentError, "natural sequence event_ids must be unique strings" unless string_array?(sequence["event_ids"], allow_empty: true) && sequence["event_ids"].uniq.length == sequence["event_ids"].length
    end

    def validate_prior_gate!(phase, path)
      if phase == 1
        raise ArgumentError, "phase 1 must not have a prior gate report" unless path.nil?
        return
      end
      raise ArgumentError, "phase 2 requires a prior gate report" unless path.is_a?(String) && File.file?(path)
      prior = JsonFile.read(path)
      unless prior["gate"] == "natural-task-v2" && prior["task_id"] == TASKS.fetch(1) && prior["passed"] == true && prior["decision"] == "continue"
        raise ArgumentError, "phase 2 requires a passing phase 1 report"
      end
    end

    def require_text!(value, label)
      raise ArgumentError, "#{label} must be a non-empty string" unless value.is_a?(String) && !value.empty?
    end

    def string_array?(value, allow_empty: false)
      value.is_a?(Array) && (allow_empty || !value.empty?) && value.all? { |entry| entry.is_a?(String) && !entry.empty? }
    end

    def current_semantic_types(events)
      superseded = events.flat_map { |event| Array(event["supersedes"]) }
      events.reject { |event| %w[refuted superseded].include?(event["status"]) || superseded.include?(event["id"]) }
        .filter_map { |event| event["type"] }.uniq
    end
  end
end
