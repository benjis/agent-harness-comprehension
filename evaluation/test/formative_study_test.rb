# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"

require_relative "../lib/comprehension_study"

class FormativeStudyTest < Minitest::Test
  def test_assigns_one_reviewer_one_task_per_condition_without_claiming_an_effect
    Dir.mktmpdir("comprehension-formative-") do |directory|
      runs = %w[small-validation medium-atomic-reservation nontrivial-idempotent-dispatch]
        .each_with_index.map { |task, index| create_run(directory, task, index) }
      study = File.join(directory, "study")
      key = ComprehensionStudy::FormativeAssignmentBuilder.new.build(
        runs: runs, reviewer: "ben", destination: study, seed: 73
      )

      assert_equal "single-reviewer-formative", key.fetch("study_mode")
      assert_equal ComprehensionStudy::CONDITIONS.sort,
        key.fetch("assignments").map { |row| row.fetch("condition") }.sort
      public_assignment = JSON.parse(File.read(File.join(study, "reviewer", "assignment.json")))
      refute_includes public_assignment.to_s, "condition"

      sessions = []
      scores = []
      key.fetch("assignments").each_with_index do |assignment, index|
        sessions << write_json(directory, "session-#{index}.json", session(assignment, index))
        scores << write_json(directory, "score-#{index}.json", score(assignment, index))
      end
      result = ComprehensionStudy::ResultAnalyzer.new.analyze(
        researcher_key: File.join(study, "researcher-key.json"),
        sessions: sessions,
        scores: scores,
        destination: File.join(directory, "analysis")
      )

      assert_equal "formative-only", result.fetch("decision")
      assert_equal "not-supported", result.fetch("causal_inference")
      assert_includes File.read(File.join(directory, "analysis", "report.md")), "cannot estimate a treatment effect"
    end
  end

  private

  def create_run(directory, task, index)
    run = File.join(directory, "run-#{index}")
    FileUtils.mkdir_p(File.join(run, "repository"))
    FileUtils.mkdir_p(File.join(run, "guides", "post_hoc"))
    FileUtils.mkdir_p(File.join(run, "guides", "runtime"))
    File.write(File.join(run, "TASK.md"), "# #{task}\n")
    File.write(File.join(run, "diff.patch"), "diff\n")
    File.write(File.join(run, "visible-tests.txt"), "passed\n")
    File.write(File.join(run, "repository", "example.rb"), "VALUE = #{index}\n")
    File.write(File.join(run, "guides", "post_hoc", "review-guide.md"), "# Guide\n")
    File.write(File.join(run, "guides", "runtime", "review-guide.md"), "# Guide\n")
    ComprehensionStudy::JsonFile.write(File.join(run, "run.json"), {
      "schema_version" => 2,
      "task_id" => task,
      "level" => index.zero? ? "small" : index == 1 ? "medium" : "non-trivial",
      "visible_tests" => "passed",
      "hidden_tests" => "passed",
      "hidden_test_failures" => 0,
      "trial_status" => "eligible"
    })
    run
  end

  def session(assignment, index)
    {
      "packet_id" => assignment.fetch("packet_id"),
      "reviewer" => assignment.fetch("reviewer"),
      "duration_seconds" => 300 + index,
      "timed_out" => false,
      "unique_opened_files" => ["repository/example.rb"],
      "answers" => {
        "confidence" => ComprehensionStudy::REVIEW_FIELDS.to_h { |field| [field, 3] },
        "cognitive_load" => 4
      }
    }
  end

  def score(assignment, index)
    {
      "packet_id" => assignment.fetch("packet_id"),
      "reviewer" => assignment.fetch("reviewer"),
      "scorer" => "self-after-unblinding",
      "artifact_defects" => [],
      **ComprehensionStudy::SCORE_FIELDS.to_h { |field| [field, index % 3] }
    }
  end

  def write_json(directory, name, value)
    path = File.join(directory, name)
    ComprehensionStudy::JsonFile.write(path, value)
    path
  end
end
