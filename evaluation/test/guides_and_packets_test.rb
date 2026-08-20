# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"

require_relative "../lib/comprehension_study"

class GuidesAndPacketsTest < Minitest::Test
  def test_registers_matched_guides_and_builds_three_blinded_packets
    Dir.mktmpdir("comprehension-guides-") do |directory|
      run = create_awaiting_run(directory)
      post_hoc = write_guide(directory, "post.md", "Final evidence explains the change.")
      runtime = write_guide(directory, "runtime.md", "Runtime evidence explains the choice.")
      current_state = File.join(directory, "current-state.json")
      File.write(current_state, "{}\n")

      record = ComprehensionStudy::GuideRegistrar.new.attach(
        run: run, post_hoc: post_hoc, runtime: runtime, current_state: current_state
      )
      assert_equal "eligible", record.fetch("trial_status")

      packets = {}
      ComprehensionStudy::CONDITIONS.each_with_index do |condition, index|
        destination = File.join(directory, "packet-#{condition}")
        ComprehensionStudy::PacketBuilder.new.build(
          run: run, destination: destination, packet_id: "P#{index}", condition: condition
        )
        packets[condition] = destination
        manifest = JSON.parse(File.read(File.join(destination, "packet.json")))
        refute manifest.key?("condition")
      end

      refute_path_exists File.join(packets.fetch("ordinary"), "review-guide.md")
      assert_includes File.read(File.join(packets.fetch("post_hoc"), "review-guide.md")), "Final evidence"
      assert_includes File.read(File.join(packets.fetch("runtime"), "review-guide.md")), "Runtime evidence"
    end
  end

  private

  def create_awaiting_run(directory)
    run = File.join(directory, "run")
    FileUtils.mkdir_p(File.join(run, "repository"))
    File.write(File.join(run, "TASK.md"), "# Task\n")
    File.write(File.join(run, "diff.patch"), "diff\n")
    File.write(File.join(run, "visible-tests.txt"), "passed\n")
    File.write(File.join(run, "repository", "example.rb"), "VALUE = 1\n")
    ComprehensionStudy::JsonFile.write(File.join(run, "run.json"), {
      "schema_version" => 2,
      "task_id" => "small-validation",
      "level" => "small",
      "visible_tests" => "passed",
      "hidden_tests" => "failed",
      "hidden_test_failures" => 1,
      "trial_status" => "awaiting-guides"
    })
    run
  end

  def write_guide(directory, name, sentence)
    path = File.join(directory, name)
    File.write(path, "# Review Guide\n\n## Change\n\n#{sentence}\n")
    path
  end
end
