# frozen_string_literal: true

require "openssl"
require "json"

module Mppx
  module Challenge
    METHOD_PATTERN = /\A[a-z][a-z0-9:_-]*\z/

    module_function

    def from(params)
      secret_key = params[:secret_key]
      meta = params[:meta]

      challenge = {
        realm: params[:realm],
        method: params[:method],
        intent: params[:intent],
        request: params[:request]
      }
      challenge[:description] = params[:description] if params[:description]
      challenge[:digest] = params[:digest] if params[:digest]
      challenge[:expires] = params[:expires] if params[:expires]
      challenge[:opaque] = meta if meta

      challenge[:id] = if secret_key
                         compute_id(challenge, secret_key)
                       else
                         params[:id]
                       end

      challenge
    end

    def from_method(method, params)
      request = PaymentRequest.from_method(method, params[:request])

      from(
        id: params[:id],
        secret_key: params[:secret_key],
        realm: params[:realm],
        method: method[:name],
        intent: method[:intent],
        request: request,
        description: params[:description],
        digest: params[:digest],
        expires: params[:expires],
        meta: params[:meta]
      )
    end

    def serialize(challenge)
      parts = [
        "id=\"#{challenge[:id]}\"",
        "realm=\"#{challenge[:realm]}\"",
        "method=\"#{challenge[:method]}\"",
        "intent=\"#{challenge[:intent]}\"",
        "request=\"#{PaymentRequest.serialize(challenge[:request])}\""
      ]

      parts << "description=\"#{challenge[:description]}\"" if challenge[:description]
      parts << "digest=\"#{challenge[:digest]}\"" if challenge[:digest]
      parts << "expires=\"#{challenge[:expires]}\"" if challenge[:expires]
      parts << "opaque=\"#{PaymentRequest.serialize(challenge[:opaque])}\"" if challenge[:opaque]

      "Payment #{parts.join(", ")}"
    end

    def deserialize(value)
      params_str = extract_payment_auth_params(value)
      raise "Missing Payment scheme." unless params_str

      result = parse_auth_params(params_str)

      request_encoded = result.delete("request")
      raise "Missing request parameter." unless request_encoded

      method_name = result["method"]
      if method_name && !METHOD_PATTERN.match?(method_name)
        raise "Invalid method: \"#{method_name}\". Must be lowercase per spec."
      end

      opaque_encoded = result.delete("opaque")

      challenge = {
        id: result["id"],
        realm: result["realm"],
        method: result["method"],
        intent: result["intent"],
        request: PaymentRequest.deserialize(request_encoded)
      }
      challenge[:description] = result["description"] if result["description"]
      challenge[:digest] = result["digest"] if result["digest"]
      challenge[:expires] = result["expires"] if result["expires"]
      challenge[:opaque] = PaymentRequest.deserialize(opaque_encoded) if opaque_encoded

      challenge
    end

    def deserialize_list(value)
      starts = []
      value.scan(/Payment\s+/i) do
        starts << Regexp.last_match.begin(0)
      end
      raise "No Payment schemes found." if starts.empty?

      starts.each_with_index.map do |start, i|
        end_pos = i + 1 < starts.length ? starts[i + 1] : value.length
        chunk = value[start...end_pos].sub(/,\s*\z/, "")
        deserialize(chunk)
      end
    end

    def from_headers(headers)
      header = headers["WWW-Authenticate"] || headers["www-authenticate"]
      raise "Missing WWW-Authenticate header." unless header

      deserialize(header)
    end

    def from_response(status:, headers:)
      raise "Response status is not 402." unless status == 402

      from_headers(headers)
    end

    def verify(challenge, secret_key:)
      expected_id = compute_id(challenge, secret_key)
      ConstantTimeEqual.call(challenge[:id], expected_id)
    end

    def meta(challenge)
      challenge[:opaque]
    end

    # @private
    def compute_id(challenge, secret_key)
      input = [
        challenge[:realm],
        challenge[:method],
        challenge[:intent],
        PaymentRequest.serialize(challenge[:request]),
        challenge[:expires] || "",
        challenge[:digest] || "",
        challenge[:opaque] ? PaymentRequest.serialize(challenge[:opaque]) : ""
      ].join("|")

      mac = OpenSSL::HMAC.digest("SHA256", secret_key, input)
      Base64Url.encode(mac)
    end

    # @private - Extract Payment scheme from a multi-scheme WWW-Authenticate header
    def extract_payment_auth_params(header)
      token = "Payment"
      in_quotes = false
      escaped = false

      header.length.times do |i|
        char = header[i]

        if in_quotes
          if escaped
            escaped = false
          elsif char == "\\"
            escaped = true
          elsif char == '"'
            in_quotes = false
          end
          next
        end

        if char == '"'
          in_quotes = true
          next
        end

        next unless starts_with_scheme_token?(header, i, token)

        prefix = header[0...i]
        next if prefix.strip.length > 0 && !prefix.rstrip.end_with?(",")

        params_start = i + token.length
        params_start += 1 while params_start < header.length && header[params_start] =~ /\s/
        return header[params_start..]
      end

      nil
    end

    # @private
    def starts_with_scheme_token?(value, index, token)
      return false unless value[index..].downcase.start_with?(token.downcase)

      next_char = value[index + token.length]
      next_char && next_char =~ /\s/
    end

    # @private - Parse auth-params with support for escaped quoted-string values
    def parse_auth_params(input)
      result = {}
      i = 0

      while i < input.length
        # Skip whitespace and commas
        i += 1 while i < input.length && input[i] =~ /[\s,]/
        break if i >= input.length

        # Read key
        key_start = i
        i += 1 while i < input.length && input[i] =~ /[A-Za-z0-9_-]/
        key = input[key_start...i]
        raise "Malformed auth-param." if key.empty?

        # Skip whitespace
        i += 1 while i < input.length && input[i] =~ /\s/

        # If no '=' after token, likely another auth scheme
        break if input[i] != "="
        i += 1

        # Skip whitespace
        i += 1 while i < input.length && input[i] =~ /\s/

        # Read value
        value, i = read_auth_param_value(input, i)

        raise "Duplicate parameter: #{key}" if result.key?(key)

        result[key] = value
      end

      result
    end

    # @private
    def read_auth_param_value(input, start)
      if input[start] == '"'
        read_quoted_auth_param_value(input, start + 1)
      else
        i = start
        i += 1 while i < input.length && input[i] != ","
        [input[start...i].strip, i]
      end
    end

    # @private
    def read_quoted_auth_param_value(input, start)
      i = start
      value = +""
      escaped = false

      while i < input.length
        char = input[i]
        i += 1

        if escaped
          value << char
          escaped = false
          next
        end

        if char == "\\"
          escaped = true
          next
        end

        return [value, i] if char == '"'

        value << char
      end

      raise "Unterminated quoted-string."
    end
  end
end
