# frozen_string_literal: true

require "json"

module Mppx
  module Store
    module_function

    def memory
      store = {}
      from(
        get: ->(key) { store.key?(key) ? JSON.parse(store[key]) : nil },
        put: ->(key, value) { store[key] = JSON.generate(value) },
        delete: ->(key) { store.delete(key) }
      )
    end

    def redis(client)
      from(
        get: ->(key) {
          raw = client.get(key)
          raw.nil? ? nil : JSON.parse(raw)
        },
        put: ->(key, value) { client.set(key, JSON.generate(value)) },
        delete: ->(key) { client.del(key) }
      )
    end

    def from(store)
      store
    end
  end
end
