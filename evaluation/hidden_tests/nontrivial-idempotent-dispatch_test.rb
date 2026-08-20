# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "parcel_flow"

class NontrivialIdempotentDispatchHiddenTest < Minitest::Test
  def test_retry_through_a_new_dispatcher_reuses_the_persisted_result
    Dir.mktmpdir do |directory|
      path = File.join(directory, "dispatches.json")
      log = ParcelFlow::DispatchLog.new(path)
      shipment = ParcelFlow::Shipment.new(
        id: "S-retry",
        destination: { "country" => "AU" },
        items: { "book" => 1 }
      )
      first_inventory = ParcelFlow::Inventory.new("book" => 1)
      assert_equal "domestic", ParcelFlow::Dispatcher.new(inventory: first_inventory, log: log).dispatch(shipment)

      retry_inventory = ParcelFlow::Inventory.new("book" => 0)
      route = ParcelFlow::Dispatcher.new(inventory: retry_inventory, log: ParcelFlow::DispatchLog.new(path)).dispatch(shipment)

      assert_equal "domestic", route
      assert_equal 0, retry_inventory.available("book")
      assert_equal 1, log.entries.length
    end
  end
end
