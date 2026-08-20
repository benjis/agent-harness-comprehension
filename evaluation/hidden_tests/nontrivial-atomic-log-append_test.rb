# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require "parcel_flow"

class NontrivialAtomicLogAppendHiddenTest < Minitest::Test
  def test_partial_write_failure_preserves_original_and_cleans_temp_file
    Dir.mktmpdir do |directory|
      path = File.join(directory, "dispatches.json")
      original = JSON.pretty_generate([{ "shipment_id" => "S-1", "route" => "domestic" }]) + "\n"
      File.binwrite(path, original)
      failure = IOError.new("injected partial write")
      ordinary_write = File.method(:write)

      error = File.stub(:write, lambda { |target, contents, *arguments|
        if File.basename(target).start_with?(".dispatches.json.tmp-")
          File.binwrite(target, contents.byteslice(0, 7))
          raise failure
        end
        ordinary_write.call(target, contents, *arguments)
      }) do
        assert_raises(IOError) do
          ParcelFlow::DispatchLog.new(path).append(shipment_id: "S-2", route: "international")
        end
      end

      assert_same failure, error
      assert_equal original, File.binread(path)
      assert_empty Dir.glob(File.join(directory, ".dispatches.json.tmp-*"))
    end
  end

  def test_successful_append_remains_readable
    Dir.mktmpdir do |directory|
      log = ParcelFlow::DispatchLog.new(File.join(directory, "dispatches.json"))

      log.append(shipment_id: "S-1", route: "domestic")
      log.append(shipment_id: "S-2", route: "international")

      assert_equal [
        { "shipment_id" => "S-1", "route" => "domestic" },
        { "shipment_id" => "S-2", "route" => "international" }
      ], log.entries
    end
  end
end
