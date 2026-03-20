# frozen_string_literal: true

require "base64"

module Mppx
  module Base64Url
    module_function

    def encode(data)
      Base64.urlsafe_encode64(data, padding: false)
    end

    def decode(data)
      # Add padding if needed
      padded = case data.length % 4
               when 2 then "#{data}=="
               when 3 then "#{data}="
               else data
               end
      Base64.urlsafe_decode64(padded)
    end
  end
end
