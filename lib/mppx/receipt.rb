# frozen_string_literal: true

require "json"

module Mppx
  module Receipt
    module_function

    def from(method:, reference:, status: "success", timestamp:, external_id: nil)
      raise ArgumentError, "status must be 'success'" unless status == "success"

      receipt = {
        method: method,
        reference: reference,
        status: status,
        timestamp: timestamp
      }
      receipt[:externalId] = external_id if external_id
      receipt
    end

    def serialize(receipt)
      json = JSON.generate(receipt)
      Base64Url.encode(json)
    end

    def deserialize(encoded)
      json = Base64Url.decode(encoded)
      parsed = JSON.parse(json)
      {
        method: parsed["method"],
        reference: parsed["reference"],
        status: parsed["status"],
        timestamp: parsed["timestamp"]
      }.tap do |r|
        r[:externalId] = parsed["externalId"] if parsed["externalId"]
      end
    end

    def from_response(headers)
      header = headers["Payment-Receipt"] || headers["payment-receipt"]
      raise "Missing Payment-Receipt header." unless header

      deserialize(header)
    end
  end
end
