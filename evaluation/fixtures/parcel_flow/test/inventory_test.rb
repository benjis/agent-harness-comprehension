# frozen_string_literal: true

require_relative "test_helper"

class InventoryTest < Minitest::Test
  def test_reserves_available_stock
    inventory = ParcelFlow::Inventory.new("book" => 3)

    inventory.reserve("book" => 2)

    assert_equal 1, inventory.available("book")
  end
end
