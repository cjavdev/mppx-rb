# frozen_string_literal: true

require "json"

module Mppx
  module CanonicalJson
    module_function

    def canonicalize(obj)
      JSON.generate(deep_sort(obj))
    end

    def deep_sort(obj)
      case obj
      when Hash
        obj.keys.sort.each_with_object({}) do |key, sorted|
          sorted[key] = deep_sort(obj[key])
        end
      when Array
        obj.map { |item| deep_sort(item) }
      else
        obj
      end
    end
  end
end
