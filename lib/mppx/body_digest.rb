# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

module Mppx
  module BodyDigest
    module_function

    def compute(body)
      str = body.is_a?(Hash) ? JSON.generate(body) : body
      hash = OpenSSL::Digest::SHA256.digest(str)
      "sha-256=#{Base64.strict_encode64(hash)}"
    end

    def verify(digest, body)
      ConstantTimeEqual.call(compute(body), digest)
    end
  end
end
