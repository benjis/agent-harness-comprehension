# frozen_string_literal: true

module ParcelFlow
  class Inventory
    def initialize(stock)
      @stock = stock.transform_keys(&:to_s)
    end

    def reserve(items)
      items.each do |sku, quantity|
        available = @stock.fetch(sku, 0)
        raise ArgumentError, "insufficient stock for #{sku}" if available < quantity

        @stock[sku] = available - quantity
      end
    end

    def available(sku)
      @stock.fetch(sku.to_s, 0)
    end
  end
end
