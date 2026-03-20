# frozen_string_literal: true

require "json"

module Mppx
  module Server
    module Transport
      module_function

      def http
        {
          name: "http",

          get_credential: ->(env) {
            header = env["HTTP_AUTHORIZATION"]
            return nil unless header

            payment = Credential.extract_payment_scheme(header)
            return nil unless payment

            Credential.deserialize(payment)
          },

          respond_challenge: ->(challenge:, error: nil, **_opts) {
            headers = {
              "WWW-Authenticate" => Challenge.serialize(challenge),
              "Cache-Control" => "no-store"
            }

            body = nil
            if error
              headers["Content-Type"] = "application/problem+json"
              body = JSON.generate(error.to_problem_details(challenge[:id]))
            end

            [error&.status || 402, headers, body ? [body] : []]
          },

          respond_receipt: ->(receipt:, response:, challenge_id: nil) {
            status, headers, body = response
            new_headers = headers.dup
            new_headers["Payment-Receipt"] = Receipt.serialize(receipt)
            [status, new_headers, body]
          }
        }
      end
    end
  end
end
