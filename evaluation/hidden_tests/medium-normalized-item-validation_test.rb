# frozen_string_literal: true

require "minitest/autorun"
require "parcel_flow"

class MediumNormalizedItemValidationHiddenTest < Minitest::Test
  def test_rejects_keys_that_collide_after_normalization
    error = assert_raises(ArgumentError) do
      ParcelFlow::Shipment.new(
        id: "S-collision",
        destination: { "country" => "AU" },
        items: { book: 1, "book" => 2 }
      )
    end

    assert_match(/duplicate|collision|book/i, error.message)
  end

  def test_rejects_every_non_positive_or_non_integer_quantity
    [0, -1, 1.5, "1", nil].each do |quantity|
      assert_raises(ArgumentError) do
        ParcelFlow::Shipment.new(
          id: "S-invalid",
          destination: { "country" => "AU" },
          items: { "book" => quantity }
        )
      end
    end
  end

  def test_exposes_frozen_normalized_items
    shipment = ParcelFlow::Shipment.new(
      id: "S-valid",
      destination: { "country" => "AU" },
      items: { book: 2 }
    )

    assert_equal({ "book" => 2 }, shipment.items)
    assert_predicate shipment.items, :frozen?
  end
end
