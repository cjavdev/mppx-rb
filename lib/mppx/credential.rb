# frozen_string_literal: true

require "json"

module Mppx
  module Credential
    module_function

    def from(challenge:, payload:, source: nil)
      credential = {
        challenge: challenge,
        payload: payload
      }
      credential[:source] = source if source
      credential
    end

    def serialize(credential)
      wire = {
        challenge: credential[:challenge].merge(
          request: PaymentRequest.serialize(credential[:challenge][:request])
        ),
        payload: credential[:payload]
      }
      wire[:source] = credential[:source] if credential[:source]
      json = JSON.generate(wire)
      encoded = Base64Url.encode(json)
      "Payment #{encoded}"
    end

    def deserialize(value)
      match = value.match(/\APayment\s+(.+)\z/i)
      raise "Missing Payment scheme." unless match

      begin
        json = Base64Url.decode(match[1])
        parsed = JSON.parse(json)

        challenge_data = parsed["challenge"]
        request = PaymentRequest.deserialize(challenge_data["request"])

        challenge = {
          id: challenge_data["id"],
          realm: challenge_data["realm"],
          method: challenge_data["method"],
          intent: challenge_data["intent"],
          request: request
        }
        challenge[:description] = challenge_data["description"] if challenge_data["description"]
        challenge[:digest] = challenge_data["digest"] if challenge_data["digest"]
        challenge[:expires] = challenge_data["expires"] if challenge_data["expires"]
        challenge[:opaque] = challenge_data["opaque"] if challenge_data["opaque"]

        credential = {
          challenge: challenge,
          payload: parsed["payload"]
        }
        credential[:source] = parsed["source"] if parsed["source"]
        credential
      rescue StandardError
        raise "Invalid base64url or JSON."
      end
    end

    def from_request(request)
      header = request[:headers]["Authorization"] || request[:headers]["HTTP_AUTHORIZATION"]
      raise "Missing Authorization header." unless header

      payment = extract_payment_scheme(header)
      raise "Missing Payment scheme." unless payment

      deserialize(payment)
    end

    def from_rack_request(env)
      header = env["HTTP_AUTHORIZATION"]
      raise "Missing Authorization header." unless header

      payment = extract_payment_scheme(header)
      raise "Missing Payment scheme." unless payment

      deserialize(payment)
    end

    def extract_payment_scheme(header)
      schemes = header.split(",").map(&:strip)
      schemes.find { |s| s =~ /\APayment\s+/i }
    end
  end
end
