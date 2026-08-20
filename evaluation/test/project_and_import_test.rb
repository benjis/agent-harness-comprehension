# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"

require_relative "../lib/comprehension_study"

class ProjectAndImportTest < Minitest::Test
  def test_prepares_and_imports_a_pi_workspace_without_dsh
    Dir.mktmpdir("comprehension-import-") do |directory|
      workspace = File.join(directory, "workspace")
      prepared = ComprehensionStudy::ProjectFactory.new.prepare(
        task_id: "small-validation", destination: workspace
      )
      assert_equal "small-validation", prepared.fetch("task_id")
      assert File.file?(File.join(workspace, "lib", "parcel_flow", "shipment.rb"))

      shipment = File.join(workspace, "lib", "parcel_flow", "shipment.rb")
      File.open(shipment, "a") { |file| file.write("\n# committed agent change\n") }
      assert system("git", "add", "lib/parcel_flow/shipment.rb", chdir: workspace)
      assert system("git", "commit", "-m", "agent change", chdir: workspace)
      File.write(File.join(workspace, "agent-note.txt"), "untracked evidence\n")
      session = File.join(workspace, ".pi", "comprehension", "session-1")
      FileUtils.mkdir_p(session)
      ledger = File.join(session, "events.jsonl")
      File.write(ledger, "{\"family\":\"semantic\",\"type\":\"goal\"}\n")
      File.write(File.join(session, "mental-model.md"), "# Mental Model\n")

      run = File.join(directory, "run")
      record = ComprehensionStudy::RunImporter.new.import(
        task_id: "small-validation", workspace: workspace, ledger: ledger, output: run
      )

      assert_equal "awaiting-guides", record.fetch("trial_status")
      assert_equal prepared.fetch("baseline_revision"), record.fetch("baseline_revision")
      assert_equal "passed", record.fetch("visible_tests")
      assert_equal "failed", record.fetch("hidden_tests")
      assert_equal "present", record.dig("capture", "ledger")
      assert_includes File.read(File.join(run, "diff.patch")), "agent-note.txt"
      assert_includes File.read(File.join(run, "diff.patch")), "committed agent change"
      assert File.file?(File.join(run, "research", "runtime-events.jsonl"))
      assert File.file?(File.join(run, "research", "pi-mental-model.md"))
      refute_path_exists File.join(run, "repository", ".pi")
    end
  end

  def test_records_a_missing_ledger_as_a_capture_failure
    Dir.mktmpdir("comprehension-import-") do |directory|
      workspace = File.join(directory, "workspace")
      ComprehensionStudy::ProjectFactory.new.prepare(
        task_id: "small-validation", destination: workspace
      )

      record = ComprehensionStudy::RunImporter.new.import(
        task_id: "small-validation",
        workspace: workspace,
        ledger: "-",
        output: File.join(directory, "run")
      )

      assert_equal "capture-missing", record.fetch("trial_status")
      assert_equal "missing", record.dig("capture", "ledger")
    end
  end
end
