# frozen_string_literal: true

require_relative "test_helper"

class DispatcherTest < Minitest::Test
  def test_dispatches_a_domestic_shipment
    Dir.mktmpdir do |directory|
      inventory = ParcelFlow::Inventory.new("book" => 2)
      log = ParcelFlow::DispatchLog.new(File.join(directory, "dispatches.json"))
      dispatcher = ParcelFlow::Dispatcher.new(inventory: inventory, log: log)
      shipment = ParcelFlow::Shipment.new(
        id: "S-1",
        destination: { "country" => "AU" },
        items: { "book" => 1 }
      )

      assert_equal "domestic", dispatcher.dispatch(shipment)
      assert_equal 1, inventory.available("book")
      assert_equal [{ "shipment_id" => "S-1", "route" => "domestic" }], log.entries
    end
  end
end
