# frozen_string_literal: true

require "openssl"

module Mppx
  module ConstantTimeEqual
    module_function

    def call(a, b)
      hash_a = OpenSSL::Digest::SHA256.hexdigest(a)
      hash_b = OpenSSL::Digest::SHA256.hexdigest(b)
      result = 0
      hash_a.bytes.each_with_index do |byte, i|
        result |= byte ^ hash_b.bytes[i]
      end
      result == 0
    end
  end
end
