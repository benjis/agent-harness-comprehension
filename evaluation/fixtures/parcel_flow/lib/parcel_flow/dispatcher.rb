# frozen_string_literal: true

module ParcelFlow
  class Dispatcher
    def initialize(inventory:, log:)
      @inventory = inventory
      @log = log
    end

    def dispatch(shipment)
      @inventory.reserve(shipment.items)
      route = route_for(shipment.destination)
      @log.append(shipment_id: shipment.id, route: route)
      route
    end

    private

    def route_for(destination)
      destination.fetch("country") == "AU" ? "domestic" : "international"
    end
  end
end
