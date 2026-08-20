# frozen_string_literal: true

require_relative "test_helper"

class ShipmentTest < Minitest::Test
  def test_requires_at_least_one_item
    error = assert_raises(ArgumentError) do
      ParcelFlow::Shipment.new(id: "S-1", destination: { "country" => "AU" }, items: {})
    end

    assert_equal "shipment must contain at least one item", error.message
  end
end
