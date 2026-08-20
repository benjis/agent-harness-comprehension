# frozen_string_literal: true

require "minitest/autorun"
require "parcel_flow"

class MediumAtomicReservationHiddenTest < Minitest::Test
  def test_a_late_failure_does_not_change_an_earlier_sku
    inventory = ParcelFlow::Inventory.new("book" => 3, "pen" => 0)

    assert_raises(ArgumentError) { inventory.reserve("book" => 2, "pen" => 1) }

    assert_equal 3, inventory.available("book")
    assert_equal 0, inventory.available("pen")
  end

  def test_rejects_zero_and_negative_quantities_without_changing_stock
    [0, -1].each do |quantity|
      inventory = ParcelFlow::Inventory.new("book" => 3)

      assert_raises(ArgumentError) { inventory.reserve("book" => quantity) }
      assert_equal 3, inventory.available("book")
    end
  end
end
