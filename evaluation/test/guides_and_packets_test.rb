# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"

require_relative "../lib/comprehension_study"

class GuidesAndPacketsTest < Minitest::Test
  TASKS = [
    ["small-validation", "small"],
    ["medium-atomic-reservation", "medium"],
    ["nontrivial-idempotent-dispatch", "non-trivial"]
  ].freeze

  def test_pipeline_renders_matched_guides_and_withholds_packets_until_gate_passes
    Dir.mktmpdir("comprehension-guides-") do |directory|
      runs = TASKS.each_with_index.map { |(task, level), index| prepare_audited_run(directory, task, level, index) }
      first = runs.first
      runtime_guide = File.join(first, "guides", "runtime", "review-guide.md")
      original_guide = File.binread(runtime_guide)
      File.write(runtime_guide, original_guide + "manual edit\n")
      refute ComprehensionStudy::ArtifactIntegrity.new.verify(first)
      File.write(runtime_guide, original_guide)
      assert ComprehensionStudy::ArtifactIntegrity.new.verify(first)
      assert_raises(ArgumentError) do
        ComprehensionStudy::PacketBuilder.new.build(
          run: first, destination: File.join(directory, "early-packet"), packet_id: "early", condition: "ordinary"
        )
      end

      report = ComprehensionStudy::FormativeGate.new.evaluate(
        runs: runs, destination: File.join(directory, "gate.json")
      )
      assert report.fetch("passed")
      assert runs.all? { |run| read_json(File.join(run, "run.json")).fetch("trial_status") == "eligible" }

      packets = {}
      ComprehensionStudy::CONDITIONS.each_with_index do |condition, index|
        destination = File.join(directory, "packet-#{condition}")
        ComprehensionStudy::PacketBuilder.new.build(
          run: first, destination: destination, packet_id: "P#{index}", condition: condition
        )
        packets[condition] = destination
        refute read_json(File.join(destination, "packet.json")).key?("condition")
      end
      refute_path_exists File.join(packets.fetch("ordinary"), "review-guide.md")
      assert_includes File.read(File.join(packets.fetch("post_hoc"), "review-guide.md")), "post-001"
      assert_includes File.read(File.join(packets.fetch("runtime"), "review-guide.md")), "run-001"
      post_current = File.read(File.join(packets.fetch("post_hoc"), "review-guide.md")).split("## Decisions", 2).first
      runtime_current = File.read(File.join(packets.fetch("runtime"), "review-guide.md")).split("## Decisions", 2).first
      assert_equal post_current, runtime_current
    end
  end

  def test_runtime_summary_excludes_superseded_semantic_events_from_current_closure
    Dir.mktmpdir("comprehension-ledger-") do |directory|
      path = File.join(directory, "events.jsonl")
      events = [
        event("sem-1", "decision"),
        event("sem-2", "revision", "supersedes" => ["sem-1"])
      ]
      File.write(path, events.map { |entry| JSON.generate(entry) }.join("\n") + "\n")

      summary = ComprehensionStudy::RuntimeLedger.new.read(path)
      assert_equal({ "decision" => 1, "revision" => 1 }, summary.fetch("semantic_types"))
      assert_equal({ "revision" => 1 }, summary.fetch("current_semantic_types"))
      assert_equal 1, summary.fetch("supersession_links")
    end
  end

  def test_audit_rejects_an_omitted_claim
    Dir.mktmpdir("comprehension-audit-") do |directory|
      run, inputs = create_awaiting_run(directory, "small-validation", "small", 0)
      ComprehensionStudy::ArtifactPipeline.new.register(run: run, **inputs)
      audit = audit_document("small-validation", include_history: false, runtime_unique: false)
      path = write_json(directory, "incomplete-audit.json", audit)

      error = assert_raises(ArgumentError) { ComprehensionStudy::ClaimAuditor.new.register(run: run, audit: path) }
      assert_includes error.message, "every claim"
      assert_equal "awaiting-audit", read_json(File.join(run, "run.json")).fetch("trial_status")
    end
  end

  private

  def prepare_audited_run(directory, task, level, index)
    run, inputs = create_awaiting_run(directory, task, level, index)
    record = ComprehensionStudy::ArtifactPipeline.new.register(run: run, **inputs)
    assert_equal "awaiting-audit", record.fetch("trial_status")
    manifest = read_json(File.join(run, "research", "artifacts", "generation-manifest.json"))
    assert_equal 4, manifest.dig("runtime_summary", "semantic_events")
    audit = audit_document(task, include_history: true, runtime_unique: level != "small")
    audit_path = write_json(directory, "audit-#{index}.json", audit)
    ComprehensionStudy::ClaimAuditor.new.register(run: run, audit: audit_path)
    run
  end

  def create_awaiting_run(directory, task, level, index)
    run = File.join(directory, "run-#{index}")
    FileUtils.mkdir_p(File.join(run, "repository"))
    FileUtils.mkdir_p(File.join(run, "research"))
    File.write(File.join(run, "TASK.md"), "# Task\n")
    File.write(File.join(run, "diff.patch"), "diff\n")
    File.write(File.join(run, "visible-tests.txt"), "passed\n")
    File.write(File.join(run, "repository", "example.rb"), "VALUE = #{index}\n")
    events = %w[goal decision constraint validation].map.with_index do |type, event_index|
      JSON.generate(
        "id" => "e#{event_index + 1}", "timestamp" => "2026-08-20T00:00:00Z",
        "family" => "semantic", "type" => type, "summary" => "#{type} summary"
      )
    end
    File.write(File.join(run, "research", "runtime-events.jsonl"), events.join("\n") + "\n")
    ComprehensionStudy::JsonFile.write(File.join(run, "run.json"), {
      "schema_version" => 2,
      "task_id" => task,
      "level" => level,
      "visible_tests" => "passed",
      "hidden_tests" => "failed",
      "hidden_test_failures" => 1,
      "trial_status" => "awaiting-guides"
    })

    inputs = {
      current_state: write_json(directory, "current-#{index}.json", current_state(task)),
      post_hoc: write_json(directory, "post-#{index}.json", history(task, "post_hoc")),
      runtime: write_json(directory, "runtime-#{index}.json", history(task, "runtime")),
      generation: write_json(directory, "generation-#{index}.json", generation_metadata)
    }
    [run, inputs]
  end

  def current_state(task)
    claims = %w[change flow invariants impact validation].map.with_index do |section, index|
      {
        "id" => format("cur-%03d", index + 1),
        "section" => section,
        "summary" => "The final implementation records the #{section} behavior.",
        "evidence" => [{ "source" => "repository/example.rb", "locator" => "VALUE" }]
      }
    end
    { "schema_version" => 1, "task_id" => task, "claims" => claims }
  end

  def history(task, condition)
    prefix = condition == "post_hoc" ? "post" : "run"
    source = condition == "post_hoc" ? "diff.patch" : "runtime:e2"
    {
      "schema_version" => 1,
      "task_id" => task,
      "condition" => condition,
      "claims" => [{
        "id" => "#{prefix}-001",
        "summary" => "A recorded decision explains the selected implementation path.",
        "status" => "current",
        "evidence" => [{ "source" => source, "locator" => "decision evidence" }]
      }]
    }
  end

  def generation_metadata
    step = { "input_tokens" => 10, "output_tokens" => 5, "wall_time_ms" => 20, "retries" => 0, "failure_codes" => [] }
    {
      "schema_version" => 1,
      "generator" => { "provider" => "test", "model" => "fixture", "prompt_version" => "artifact-pipeline-v1", "settings" => {} },
      "steps" => { "current_state" => step, "post_hoc" => step, "runtime" => step }
    }
  end

  def event(id, type, extra = {})
    {
      "id" => id, "timestamp" => "2026-08-20T00:00:00Z", "family" => "semantic",
      "type" => type, "summary" => "#{type} summary", **extra
    }
  end

  def audit_document(task, include_history:, runtime_unique:)
    ids = (1..5).map { |index| format("cur-%03d", index) }
    ids += %w[post-001 run-001] if include_history
    claims = ids.map do |id|
      {
        "claim_id" => id,
        "final_state_support" => "supported",
        "runtime_support" => id.start_with?("run-") ? "observed-transition" : "not-present",
        "recoverability" => id.start_with?("run-") && runtime_unique ? "runtime-unique" : "post-hoc-recoverable",
        "decision_relevance" => id.start_with?("run-") ? "review-relevant" : "contextual",
        "target_outcome" => "architecture",
        "severity_if_wrong" => "medium"
      }
    end
    {
      "schema_version" => 1,
      "task_id" => task,
      "claims" => claims,
      "instrument" => {
        "duplicate_semantic_event_rate" => 0.0, "generic_semantic_event_rate" => 0.0,
        "capture_failures" => [], "renderer_failures" => [], "prohibited_data_findings" => [],
        "unaccounted_failures" => [], "added_tool_calls" => 0, "added_turns" => 0,
        "capture_tokens" => 0, "capture_wall_time_ms" => 0, "storage_bytes" => 100
      }
    }
  end

  def write_json(directory, name, value)
    path = File.join(directory, name)
    ComprehensionStudy::JsonFile.write(path, value)
    path
  end

  def read_json(path)
    JSON.parse(File.read(path))
  end
end
