# frozen_string_literal: true

require "json"

module ParcelFlow
  class DispatchLog
    def initialize(path)
      @path = path
    end

    def append(shipment_id:, route:)
      entries = File.exist?(@path) ? JSON.parse(File.read(@path)) : []
      entries << { "shipment_id" => shipment_id, "route" => route }
      File.write(@path, JSON.pretty_generate(entries) + "\n")
    end

    def entries
      return [] unless File.exist?(@path)

      JSON.parse(File.read(@path))
    end
  end
end
