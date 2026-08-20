# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"

require_relative "../lib/comprehension_study"

class ReviewSessionTest < Minitest::Test
  def test_records_file_opens_per_answer_confidence_and_timeout
    times = [Time.utc(2026, 8, 20, 1, 0, 0), Time.utc(2026, 8, 20, 1, 1, 0), Time.utc(2026, 8, 20, 1, 21, 0)]
    clock = -> { times.shift }
    Dir.mktmpdir("comprehension-review-") do |directory|
      packet = File.join(directory, "packet")
      FileUtils.mkdir_p(File.join(packet, "repository"))
      ComprehensionStudy::JsonFile.write(File.join(packet, "packet.json"), {
        "packet_id" => "P01", "task_id" => "small-validation", "level" => "small"
      })
      File.write(File.join(packet, "repository", "shipment.rb"), "class Shipment; end\n")
      session_path = File.join(directory, "session.json")
      session = ComprehensionStudy::ReviewSession.new(clock: clock)

      session.start(packet: packet, reviewer: "ben", destination: session_path)
      session.open(session_path: session_path, relative_path: "repository/shipment.rb")
      result = session.finish(session_path: session_path, answers: valid_answers)

      assert result.fetch("timed_out")
      assert_equal 1200, result.fetch("duration_seconds")
      assert_equal ["repository/shipment.rb"], result.fetch("unique_opened_files")
      assert_equal 4, result.dig("answers", "confidence", "impact_prediction")
    end
  end

  private

  def valid_answers
    {
      "component_model" => "Shipment owns validation.",
      "control_data_flow" => "Construction validates before dispatch.",
      "invariants" => "Invalid shipments cannot reserve inventory.",
      "impact_prediction" => "Change Shipment and its focused tests.",
      "defects" => "Whitespace handling may be incomplete.",
      "review_decision" => "Request tests before approval.",
      "evidence_traces" => [{ "claim" => "country is required", "source" => "repository/shipment.rb" }],
      "confidence" => ComprehensionStudy::REVIEW_FIELDS.to_h { |field| [field, 4] },
      "cognitive_load" => 3
    }
  end
end
