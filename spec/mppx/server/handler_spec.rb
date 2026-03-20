# frozen_string_literal: true

require "json"

RSpec.describe Mppx::Server::Handler do
  let(:realm) { "api.example.com" }
  let(:secret_key) { "test-secret-key" }

  let(:mock_method) do
    Mppx::Method.from(
      name: "mock",
      intent: "charge",
      schema: {
        credential: {
          payload: ->(p) {
            raise "missing token" unless p.is_a?(Hash) && (p[:token] || p["token"])
            p
          }
        },
        request: ->(r) { r }
      }
    )
  end

  let(:mock_verify) do
    ->(credential:, request:) {
      {
        method: "mock",
        reference: "tx-success-456",
        status: "success",
        timestamp: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
      }
    }
  end

  let(:server_method) do
    Mppx::Method.to_server(mock_method, verify: mock_verify)
  end

  let(:challenge_opts) do
    {
      amount: "1000",
      currency: "0x0000000000000000000000000000000000000001",
      recipient: "0x0000000000000000000000000000000000000002"
    }
  end

  describe ".create" do
    it "creates a handler" do
      handler = described_class.create(
        methods: [server_method],
        secret_key: secret_key,
        realm: realm
      )

      expect(handler[:realm]).to eq(realm)
      expect(handler[:handlers]).to be_a(Hash)
    end

    it "raises without secret key" do
      expect {
        described_class.create(methods: [server_method], secret_key: nil, realm: realm)
      }.to raise_error(/Missing secret key/)
    end
  end

  describe "request handling" do
    let(:handler) do
      described_class.create(
        methods: [server_method],
        secret_key: secret_key,
        realm: realm
      )
    end

    def make_env(authorization: nil)
      env = {}
      env["HTTP_AUTHORIZATION"] = authorization if authorization
      env
    end

    it "returns 402 when no Authorization header" do
      fn = handler[:handlers]["mock/charge"].call(challenge_opts)
      result = fn.call(make_env)

      expect(result[:status]).to eq(402)
      status, headers, _body = result[:challenge]
      expect(status).to eq(402)
      expect(headers["WWW-Authenticate"]).to include("Payment")
    end

    it "returns 402 for malformed credential" do
      fn = handler[:handlers]["mock/charge"].call(challenge_opts)
      result = fn.call(make_env(authorization: "Payment invalid"))

      expect(result[:status]).to eq(402)
      _status, _headers, body = result[:challenge]
      parsed = JSON.parse(body.first)
      expect(parsed["title"]).to eq("Malformed Credential")
    end

    it "returns 402 when challenge ID mismatch" do
      wrong_challenge = Mppx::Challenge.from(
        id: "wrong-id",
        intent: "charge",
        method: "mock",
        realm: realm,
        request: challenge_opts
      )
      credential = Mppx::Credential.from(
        challenge: wrong_challenge,
        payload: { token: "test" }
      )

      fn = handler[:handlers]["mock/charge"].call(challenge_opts)
      result = fn.call(make_env(authorization: Mppx::Credential.serialize(credential)))

      expect(result[:status]).to eq(402)
      _status, _headers, body = result[:challenge]
      parsed = JSON.parse(body.first)
      expect(parsed["title"]).to eq("Invalid Challenge")
      expect(parsed["detail"]).to include("not issued by this server")
    end

    it "returns 402 for cross-route scope confusion" do
      # Get a challenge from the cheap route
      cheap_fn = handler[:handlers]["mock/charge"].call(challenge_opts.merge(amount: "1"))
      cheap_result = cheap_fn.call(make_env)
      expect(cheap_result[:status]).to eq(402)

      _status, cheap_headers, _body = cheap_result[:challenge]
      cheap_challenge = Mppx::Challenge.deserialize(cheap_headers["WWW-Authenticate"])

      credential = Mppx::Credential.from(
        challenge: cheap_challenge,
        payload: { token: "valid" }
      )

      # Present at the expensive route
      expensive_fn = handler[:handlers]["mock/charge"].call(challenge_opts.merge(amount: "1000000"))
      result = expensive_fn.call(make_env(authorization: Mppx::Credential.serialize(credential)))

      expect(result[:status]).to eq(402)
      _status, _headers, body = result[:challenge]
      parsed = JSON.parse(body.first)
      expect(parsed["detail"]).to include("does not match")
    end

    it "returns 402 when credential is expired" do
      past_expires = (Time.now - 60).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")

      fn = handler[:handlers]["mock/charge"].call(challenge_opts.merge(expires: past_expires))
      first_result = fn.call(make_env)
      expect(first_result[:status]).to eq(402)

      _status, first_headers, _body = first_result[:challenge]
      challenge = Mppx::Challenge.deserialize(first_headers["WWW-Authenticate"])

      credential = Mppx::Credential.from(
        challenge: challenge,
        payload: { token: "test" }
      )

      result = fn.call(make_env(authorization: Mppx::Credential.serialize(credential)))
      expect(result[:status]).to eq(402)
      _status, _headers, body = result[:challenge]
      parsed = JSON.parse(body.first)
      expect(parsed["title"]).to eq("Payment Expired")
    end

    it "returns 402 when payload schema validation fails" do
      fn = handler[:handlers]["mock/charge"].call(
        challenge_opts.merge(expires: (Time.now + 60).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ"))
      )
      first_result = fn.call(make_env)
      expect(first_result[:status]).to eq(402)

      _status, first_headers, _body = first_result[:challenge]
      challenge = Mppx::Challenge.deserialize(first_headers["WWW-Authenticate"])

      credential = Mppx::Credential.from(
        challenge: challenge,
        payload: { invalidField: "bad" }
      )

      result = fn.call(make_env(authorization: Mppx::Credential.serialize(credential)))
      expect(result[:status]).to eq(402)
      _status, _headers, body = result[:challenge]
      parsed = JSON.parse(body.first)
      expect(parsed["title"]).to eq("Invalid Payload")
    end

    it "returns 200 when verify returns a success receipt" do
      fn = handler[:handlers]["mock/charge"].call(
        challenge_opts.merge(expires: (Time.now + 60).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ"))
      )
      first_result = fn.call(make_env)
      expect(first_result[:status]).to eq(402)

      _status, first_headers, _body = first_result[:challenge]
      challenge = Mppx::Challenge.deserialize(first_headers["WWW-Authenticate"])

      credential = Mppx::Credential.from(
        challenge: challenge,
        payload: { token: "valid-token" }
      )

      result = fn.call(make_env(authorization: Mppx::Credential.serialize(credential)))
      expect(result[:status]).to eq(200)
    end

    it "with_receipt attaches Payment-Receipt header" do
      fn = handler[:handlers]["mock/charge"].call(
        challenge_opts.merge(expires: (Time.now + 60).utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ"))
      )
      first_result = fn.call(make_env)
      _status, first_headers, _body = first_result[:challenge]
      challenge = Mppx::Challenge.deserialize(first_headers["WWW-Authenticate"])

      credential = Mppx::Credential.from(
        challenge: challenge,
        payload: { token: "valid-token" }
      )

      result = fn.call(make_env(authorization: Mppx::Credential.serialize(credential)))
      expect(result[:status]).to eq(200)

      response = result[:with_receipt].call([200, {}, ["OK"]])
      status, headers, _body = response
      expect(status).to eq(200)
      expect(headers["Payment-Receipt"]).to be_truthy
    end
  end

  describe ".compose" do
    let(:alpha_method) do
      Mppx::Method.to_server(
        Mppx::Method.from(
          name: "alpha",
          intent: "charge",
          schema: {
            credential: { payload: ->(p) { p } },
            request: ->(r) { r }
          }
        ),
        verify: ->(credential:, request:) {
          { method: "alpha", reference: "tx-alpha", status: "success",
            timestamp: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ") }
        }
      )
    end

    let(:beta_method) do
      Mppx::Method.to_server(
        Mppx::Method.from(
          name: "beta",
          intent: "charge",
          schema: {
            credential: { payload: ->(p) { p } },
            request: ->(r) { r }
          }
        ),
        verify: ->(credential:, request:) {
          { method: "beta", reference: "tx-beta", status: "success",
            timestamp: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ") }
        }
      )
    end

    let(:handler) do
      described_class.create(
        methods: [alpha_method, beta_method],
        secret_key: secret_key,
        realm: realm
      )
    end

    def make_env(authorization: nil)
      env = {}
      env["HTTP_AUTHORIZATION"] = authorization if authorization
      env
    end

    it "returns 402 with multiple challenges when no credential" do
      composed = handler[:compose].call(
        [alpha_method, challenge_opts],
        [beta_method, challenge_opts]
      )

      result = composed.call(make_env)
      expect(result[:status]).to eq(402)

      _status, headers, _body = result[:challenge]
      www_auth = headers["WWW-Authenticate"]
      expect(www_auth).to include('method="alpha"')
      expect(www_auth).to include('method="beta"')
    end

    it "throws when called with no entries" do
      expect { handler[:compose].call }.to raise_error("compose() requires at least one entry")
    end
  end
end
