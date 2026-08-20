# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "parcel_flow"

class NontrivialDispatchLogRollbackHiddenTest < Minitest::Test
  FailingLog = Struct.new(:failure) do
    def append(**)
      raise failure
    end
  end

  RecordingLog = Struct.new(:appended) do
    def append(**entry)
      self.appended = entry
    end
  end

  def test_restores_every_reserved_sku_and_reraises_the_original_exception
    inventory = ParcelFlow::Inventory.new("book" => 3, "pen" => 2)
    failure = IOError.new("disk unavailable")
    shipment = ParcelFlow::Shipment.new(
      id: "S-fail",
      destination: { "country" => "AU" },
      items: { "book" => 2, "pen" => 1 }
    )

    error = assert_raises(IOError) do
      ParcelFlow::Dispatcher.new(inventory: inventory, log: FailingLog.new(failure)).dispatch(shipment)
    end

    assert_same failure, error
    assert_equal 3, inventory.available("book")
    assert_equal 2, inventory.available("pen")
  end

  def test_does_not_compensate_when_reservation_fails
    inventory = ParcelFlow::Inventory.new("book" => 0)
    log = RecordingLog.new
    shipment = ParcelFlow::Shipment.new(
      id: "S-no-stock",
      destination: { "country" => "AU" },
      items: { "book" => 1 }
    )

    assert_raises(ArgumentError) do
      ParcelFlow::Dispatcher.new(inventory: inventory, log: log).dispatch(shipment)
    end

    assert_equal 0, inventory.available("book")
    assert_nil log.appended
  end
end
