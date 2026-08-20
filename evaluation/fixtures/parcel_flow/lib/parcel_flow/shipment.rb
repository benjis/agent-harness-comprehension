# frozen_string_literal: true

module ParcelFlow
  class Shipment
    attr_reader :id, :destination, :items

    def initialize(id:, destination:, items:)
      raise ArgumentError, "shipment must contain at least one item" if items.empty?

      @id = id
      @destination = destination
      @items = items.transform_keys(&:to_s).freeze
    end
  end
end
