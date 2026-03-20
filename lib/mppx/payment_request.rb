# frozen_string_literal: true

require "json"

module Mppx
  module PaymentRequest
    module_function

    def from(request)
      request
    end

    def from_method(method, request)
      schema = method[:schema][:request]
      schema.call(request)
    end

    def serialize(request)
      json = CanonicalJson.canonicalize(request)
      Base64Url.encode(json)
    end

    def deserialize(encoded)
      json = Base64Url.decode(encoded)
      JSON.parse(json)
    end
  end
end
