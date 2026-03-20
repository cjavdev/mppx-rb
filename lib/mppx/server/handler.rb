# frozen_string_literal: true

require "json"

module Mppx
  module Server
    module Handler
      module_function

      def create(methods:, secret_key:, realm: nil, transport: nil)
        realm ||= Env.get(:realm) || "MPP Payment"
        secret_key ||= Env.get(:secret_key)
        transport ||= Transport.http

        raise "Missing secret key. Set the MPP_SECRET_KEY environment variable or pass secret_key to Handler.create()." unless secret_key

        flat_methods = methods.flatten
        handlers = {}
        intent_count = Hash.new(0)

        flat_methods.each do |mi|
          intent_count[mi[:intent]] += 1
          key = "#{mi[:name]}/#{mi[:intent]}"
          handlers[key] = create_method_fn(
            method: mi,
            realm: realm,
            secret_key: secret_key,
            transport: transport,
            verify: mi[:verify],
            defaults: mi[:defaults],
            request_fn: mi[:request],
            respond_fn: mi[:respond]
          )
        end

        # Shorthand intent keys when unique
        flat_methods.each do |mi|
          handlers[mi[:intent]] = handlers["#{mi[:name]}/#{mi[:intent]}"] if intent_count[mi[:intent]] == 1
        end

        # Nested accessors: handler[:tempo][:charge]
        flat_methods.each do |mi|
          handlers[mi[:name]] ||= {}
          handlers[mi[:name]][mi[:intent]] = handlers["#{mi[:name]}/#{mi[:intent]}"]
        end

        {
          methods: flat_methods,
          realm: realm,
          transport: transport,
          handlers: handlers,
          compose: ->(*entries) { compose_handlers(handlers, entries) }
        }
      end

      def call_handler(handler, method_key, options)
        fn = handler[:handlers][method_key]
        raise "No handler for \"#{method_key}\"." unless fn

        fn.call(options)
      end

      def compose_handlers(handlers, entries)
        raise "compose() requires at least one entry" if entries.empty?

        configured = entries.map do |method_or_key, options|
          key = if method_or_key.is_a?(String)
                  method_or_key
                else
                  "#{method_or_key[:name]}/#{method_or_key[:intent]}"
                end
          handler_fn = handlers[key]
          raise "No handler for \"#{key}\". Is this method in your methods array?" unless handler_fn

          handler_fn.call(options)
        end

        compose(*configured)
      end

      def compose(*configured_handlers)
        raise "compose() requires at least one handler" if configured_handlers.empty?

        ->(env) {
          # Try to extract a Payment credential
          header = env["HTTP_AUTHORIZATION"]
          payment_header = header ? Credential.extract_payment_scheme(header) : nil

          if payment_header
            # Parse credential to find method+intent for dispatch
            credential = begin
              Credential.deserialize(payment_header)
            rescue StandardError
              nil
            end

            if credential
              cred_method = credential[:challenge][:method]
              cred_intent = credential[:challenge][:intent]
              cred_req = credential[:challenge][:request]

              # Filter by name+intent, then narrow by request fields
              candidates = configured_handlers.select do |h|
                meta = h.respond_to?(:_internal) ? h._internal : (h.respond_to?(:[]) && h[:_internal])
                next false unless meta && meta[:name] == cred_method && meta[:intent] == cred_intent

                canonical = meta[:_canonical_request]
                next true unless canonical

                match = true
                %w[amount currency recipient chainId].each do |field|
                  if canonical[field] && cred_req[field] && canonical[field].to_s != cred_req[field].to_s
                    match = false
                    break
                  end
                end
                match
              end

              match = candidates.first || configured_handlers.find do |h|
                meta = h.respond_to?(:_internal) ? h._internal : (h.respond_to?(:[]) && h[:_internal])
                meta && meta[:name] == cred_method && meta[:intent] == cred_intent
              end

              return match.call(env) if match
            end

            # Credential present but no match, dispatch to first handler
            return configured_handlers.first.call(env)
          end

          # No credential: call all handlers and merge 402 challenges
          results = configured_handlers.map { |h| h.call(env) }

          merged_headers = {
            "Cache-Control" => "no-store"
          }
          www_auth_parts = []
          body = nil
          content_type = nil

          results.each do |result|
            next unless result[:status] == 402

            challenge_response = result[:challenge]
            if challenge_response.is_a?(Array)
              _status, headers, resp_body = challenge_response
              www_auth = headers["WWW-Authenticate"]
              www_auth_parts << www_auth if www_auth
              unless body
                content_type = headers["Content-Type"]
                body = resp_body.is_a?(Array) ? resp_body.join : resp_body
              end
            end
          end

          merged_headers["WWW-Authenticate"] = www_auth_parts.join(", ") unless www_auth_parts.empty?
          merged_headers["Content-Type"] = content_type if content_type

          {
            status: 402,
            challenge: [402, merged_headers, body ? [body] : []]
          }
        }
      end

      # @private
      def create_method_fn(method:, realm:, secret_key:, transport:, verify:, defaults: nil, request_fn: nil, respond_fn: nil)
        ->(options) {
          description = options[:description]
          meta = options[:meta]
          merged = (defaults || {}).merge(options.reject { |k, _| %i[description meta expires].include?(k) })

          configured = ->(env) {
            expires = options.key?(:expires) ? options[:expires] : Expires.minutes(5)

            # Extract credential
            credential = nil
            credential_error = nil
            begin
              credential = transport[:get_credential].call(env)
            rescue StandardError => e
              credential_error = e
            end

            # Transform request if method provides a request function
            request = if request_fn
                        request_fn.call(credential: credential, request: merged)
                      else
                        merged
                      end

            # Recompute challenge from options (HMAC-bound, stateless)
            challenge = Challenge.from_method(method, {
              description: description,
              expires: expires,
              meta: meta,
              realm: realm,
              request: request,
              secret_key: secret_key
            })

            # Credential was provided but malformed
            if credential_error
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: Errors::MalformedCredentialError.new(reason: credential_error.message)
              )
              next { status: 402, challenge: response }
            end

            # No credential provided
            unless credential
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: Errors::PaymentRequiredError.new(description: description)
              )
              next { status: 402, challenge: response }
            end

            # Verify HMAC
            unless Challenge.verify(credential[:challenge], secret_key: secret_key)
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: Errors::InvalidChallengeError.new(
                  id: credential[:challenge][:id],
                  reason: "challenge was not issued by this server"
                )
              )
              next { status: 402, challenge: response }
            end

            # Cross-route scope confusion check
            route_req = challenge[:request]
            echoed_req = credential[:challenge][:request]
            scope_error = nil
            %w[amount currency recipient].each do |field|
              field_sym = field.to_sym
              route_val = route_req[field_sym] || route_req[field]
              echoed_val = echoed_req[field_sym] || echoed_req[field]
              if route_val && echoed_val && route_val.to_s != echoed_val.to_s
                scope_error = field
                break
              end
            end

            if scope_error
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: Errors::InvalidChallengeError.new(
                  id: credential[:challenge][:id],
                  reason: "credential #{scope_error} does not match this route's requirements"
                )
              )
              next { status: 402, challenge: response }
            end

            # Reject expired credentials
            if credential[:challenge][:expires] && Time.parse(credential[:challenge][:expires]) < Time.now
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: Errors::PaymentExpiredError.new(expires: credential[:challenge][:expires])
              )
              next { status: 402, challenge: response }
            end

            # Validate payload schema
            if method[:schema][:credential] && method[:schema][:credential][:payload]
              begin
                method[:schema][:credential][:payload].call(credential[:payload])
              rescue StandardError => e
                response = transport[:respond_challenge].call(
                  challenge: challenge,
                  error: Errors::InvalidPayloadError.new(reason: e.message)
                )
                next { status: 402, challenge: response }
              end
            end

            # User-provided verification
            receipt_data = nil
            begin
              receipt_data = verify.call(credential: credential, request: request)
            rescue Errors::PaymentError => e
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: e
              )
              next { status: 402, challenge: response }
            rescue StandardError => e
              response = transport[:respond_challenge].call(
                challenge: challenge,
                error: Errors::VerificationFailedError.new(reason: e.message)
              )
              next { status: 402, challenge: response }
            end

            # Management response via respond hook
            management_response = respond_fn ? respond_fn.call(
              credential: credential,
              receipt: receipt_data,
              request: request
            ) : nil

            {
              status: 200,
              with_receipt: ->(response = nil) {
                if management_response
                  transport[:respond_receipt].call(
                    receipt: receipt_data,
                    response: management_response,
                    challenge_id: credential[:challenge][:id]
                  )
                else
                  raise "with_receipt() requires a response argument" unless response

                  transport[:respond_receipt].call(
                    receipt: receipt_data,
                    response: response,
                    challenge_id: credential[:challenge][:id]
                  )
                end
              }
            }
          }

          # Attach internal metadata for compose dispatch
          configured.define_singleton_method(:_internal) do
            {
              name: method[:name],
              intent: method[:intent],
              _canonical_request: merged
            }
          end

          configured.define_singleton_method(:[]) do |key|
            return _internal if key == :_internal
            super(key)
          end

          configured
        }
      end
    end

    # Rack middleware
    class Middleware
      def initialize(app, handler:, method_key:, options:)
        @app = app
        @handler = handler
        @method_key = method_key
        @options = options
      end

      def call(env)
        fn = Handler.call_handler(@handler, @method_key, @options)
        result = fn.call(env)

        if result[:status] == 402
          result[:challenge]
        else
          response = @app.call(env)
          result[:with_receipt].call(response)
        end
      end
    end
  end
end
