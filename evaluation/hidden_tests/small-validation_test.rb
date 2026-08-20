# frozen_string_literal: true

require "minitest/autorun"
require "parcel_flow"

class SmallValidationHiddenTest < Minitest::Test
  def test_rejects_every_missing_or_blank_country_form
    [nil, "", "   "].each do |country|
      error = assert_raises(ArgumentError) do
        ParcelFlow::Shipment.new(
          id: "S-hidden",
          destination: { "country" => country },
          items: { "book" => 1 }
        )
      end
      assert_equal "delivery address country is required", error.message
    end
  end

  def test_still_accepts_a_present_country
    shipment = ParcelFlow::Shipment.new(
      id: "S-valid",
      destination: { "country" => "AU" },
      items: { "book" => 1 }
    )

    assert_equal "AU", shipment.destination.fetch("country")
  end
end
