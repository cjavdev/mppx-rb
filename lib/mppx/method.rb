# frozen_string_literal: true

module Mppx
  module Method
    module_function

    def from(name:, intent:, schema:)
      {
        name: name,
        intent: intent,
        schema: schema
      }.freeze
    end

    def to_client(method, create_credential:)
      method.merge(create_credential: create_credential).freeze
    end

    def to_server(method, verify:, defaults: nil, request: nil, respond: nil)
      result = method.merge(verify: verify)
      result[:defaults] = defaults if defaults
      result[:request] = request if request
      result[:respond] = respond if respond
      result.freeze
    end
  end
end
