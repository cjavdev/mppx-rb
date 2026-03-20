# frozen_string_literal: true

RSpec.describe Mppx::Challenge do
  describe ".from" do
    it "creates challenge" do
      challenge = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000", currency: "0x1234", recipient: "0xabcd" }
      )

      expect(challenge[:id]).to eq("abc123")
      expect(challenge[:realm]).to eq("api.example.com")
      expect(challenge[:method]).to eq("tempo")
      expect(challenge[:intent]).to eq("charge")
      expect(challenge[:request]).to eq(amount: "1000000", currency: "0x1234", recipient: "0xabcd")
    end

    it "creates challenge with optional fields" do
      challenge = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000" },
        digest: "sha-256=abc",
        expires: "2025-01-06T12:00:00Z"
      )

      expect(challenge[:digest]).to eq("sha-256=abc")
      expect(challenge[:expires]).to eq("2025-01-06T12:00:00Z")
    end
  end

  describe "HMAC test vectors" do
    let(:secret_key) { "test-vector-secret" }

    hmac_vectors = [
      {
        label: "required fields only",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000" } },
        expected_id: "X6v1eo7fJ76gAxqY0xN9Jd__4lUyDDYmriryOM-5FO4"
      },
      {
        label: "with expires",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000" }, expires: "2025-01-06T12:00:00Z" },
        expected_id: "ChPX33RkKSZoSUyZcu8ai4hhkvjZJFkZVnvWs5s0iXI"
      },
      {
        label: "with digest",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000" },
                  digest: "sha-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE" },
        expected_id: "JHB7EFsPVb-xsYCo8LHcOzeX1gfXWVoUSzQsZhKAfKM"
      },
      {
        label: "with expires and digest",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000" }, expires: "2025-01-06T12:00:00Z",
                  digest: "sha-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE" },
        expected_id: "m39jbWWCIfmfJZSwCfvKFFtBl0Qwf9X4nOmDb21peLA"
      },
      {
        label: "with description (not in HMAC input)",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000" }, description: "Test payment" },
        expected_id: "X6v1eo7fJ76gAxqY0xN9Jd__4lUyDDYmriryOM-5FO4"
      },
      {
        label: "with multi-field request",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000", currency: "0x1234", recipient: "0xabcd" } },
        expected_id: "_H5TOnnlW0zduQ5OhQ3EyLVze_TqxLDPda2CGZPZxOc"
      },
      {
        label: "with nested methodDetails in request",
        params: { realm: "api.example.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000", currency: "0x1234", methodDetails: { chainId: 42_431 } } },
        expected_id: "TqujwpuDDg_zsWGINAd5XObO2rRe6uYufpqvtDmr6N8"
      },
      {
        label: "with empty request",
        params: { realm: "api.example.com", method: "tempo", intent: "charge", request: {} },
        expected_id: "yLN7yChAejW9WNmb54HpJIWpdb1WWXeA3_aCx4dxmkU"
      },
      {
        label: "different realm",
        params: { realm: "payments.other.com", method: "tempo", intent: "charge",
                  request: { amount: "1000000" } },
        expected_id: "3F5bOo2a9RUihdwKk4hGRvBvzQmVPBMDvW0YM-8GD00"
      },
      {
        label: "different method",
        params: { realm: "api.example.com", method: "stripe", intent: "charge",
                  request: { amount: "1000000" } },
        expected_id: "o0ra2sd7HcB4Ph0Vns69gRDUhSj5WNOnUopcDqKPLz4"
      },
      {
        label: "different intent",
        params: { realm: "api.example.com", method: "tempo", intent: "session",
                  request: { amount: "1000000" } },
        expected_id: "aAY7_IEDzsznNYplhOSE8cERQxvjFcT4Lcn-7FHjLVE"
      }
    ]

    hmac_vectors.each do |vector|
      it "hmac: #{vector[:label]}" do
        challenge = described_class.from(**vector[:params], secret_key: secret_key)
        expect(challenge[:id]).to eq(vector[:expected_id])
      end
    end

    it "description does not affect id" do
      with_desc = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, description: "Test payment",
        secret_key: secret_key
      )
      without = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" },
        secret_key: secret_key
      )
      expect(with_desc[:id]).to eq(without[:id])
    end

    it "same params with same secretKey produce same id" do
      c1 = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "secret"
      )
      c2 = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "secret"
      )
      expect(c1[:id]).to eq(c2[:id])
    end

    it "different secretKey produces different id" do
      c1 = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "secret1"
      )
      c2 = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "secret2"
      )
      expect(c1[:id]).not_to eq(c2[:id])
    end
  end

  describe ".serialize" do
    it "serializes challenge to WWW-Authenticate header" do
      challenge = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000", currency: "USD" }
      )

      header = described_class.serialize(challenge)
      expect(header).to start_with("Payment ")
      expect(header).to include('id="abc123"')
      expect(header).to include('realm="api.example.com"')
      expect(header).to include('method="tempo"')
      expect(header).to include('intent="charge"')
      expect(header).to include('request="')
    end

    it "includes optional fields" do
      challenge = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000" },
        digest: "sha-256=abc",
        expires: "2025-01-06T12:00:00Z"
      )

      header = described_class.serialize(challenge)
      expect(header).to include('digest="sha-256=abc"')
      expect(header).to include('expires="2025-01-06T12:00:00Z"')
    end
  end

  describe ".deserialize" do
    let(:original) do
      described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000", currency: "USD" }
      )
    end

    let(:payment_header) { described_class.serialize(original) }

    it "deserializes WWW-Authenticate header" do
      challenge = described_class.deserialize(payment_header)
      expect(challenge[:id]).to eq("abc123")
      expect(challenge[:method]).to eq("tempo")
      expect(challenge[:intent]).to eq("charge")
      expect(challenge[:request]).to eq("amount" => "1000000", "currency" => "USD")
    end

    it "roundtrips with optional fields" do
      orig = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000" },
        digest: "sha-256=abc",
        expires: "2025-01-06T12:00:00Z"
      )

      header = described_class.serialize(orig)
      challenge = described_class.deserialize(header)
      expect(challenge[:digest]).to eq("sha-256=abc")
      expect(challenge[:expires]).to eq("2025-01-06T12:00:00Z")
    end

    it "extracts challenge from multi-scheme header (Payment after Bearer)" do
      header = "Bearer realm=\"api\", #{payment_header}"
      challenge = described_class.deserialize(header)
      expect(challenge[:id]).to eq("abc123")
    end

    it "handles case-insensitive scheme token" do
      header = payment_header.sub(/^Payment /, "payment ")
      challenge = described_class.deserialize(header)
      expect(challenge[:id]).to eq("abc123")
    end

    it "quoted values in previous schemes do not interfere" do
      header = "Bearer error_description=\"retry with Payment challenge\", #{payment_header}"
      challenge = described_class.deserialize(header)
      expect(challenge[:id]).to eq("abc123")
    end

    it "parses Payment params before the next scheme token" do
      header = "#{payment_header}, Bearer realm=\"fallback\""
      challenge = described_class.deserialize(header)
      expect(challenge[:id]).to eq("abc123")
    end

    context "escaped quoted-string values" do
      let(:request_encoded) do
        payment_header.match(/request="([^"]+)"/)[1]
      end

      it "deserializes escaped quotes" do
        header = "Payment id=\"abc123\", realm=\"api.example.com\", method=\"tempo\", intent=\"charge\", request=\"#{request_encoded}\", description=\"premium \\\"access\\\"\""
        challenge = described_class.deserialize(header)
        expect(challenge[:description]).to eq('premium "access"')
      end

      it "deserializes escaped comma" do
        header = "Payment id=\"abc123\", realm=\"api.example.com\", method=\"tempo\", intent=\"charge\", request=\"#{request_encoded}\", description=\"tier\\,premium\""
        challenge = described_class.deserialize(header)
        expect(challenge[:description]).to eq("tier,premium")
      end

      it "deserializes escaped backslash" do
        header = "Payment id=\"abc123\", realm=\"api.example.com\", method=\"tempo\", intent=\"charge\", request=\"#{request_encoded}\", description=\"path\\\\alpha\""
        challenge = described_class.deserialize(header)
        expect(challenge[:description]).to eq("path\\alpha")
      end
    end

    context "error cases" do
      it "throws for missing Payment scheme" do
        expect { described_class.deserialize("Bearer token") }.to raise_error("Missing Payment scheme.")
      end

      it "throws for duplicate parameters" do
        expect {
          described_class.deserialize('Payment id="a", realm="api", method="tempo", intent="charge", request="e30", id="b"')
        }.to raise_error("Duplicate parameter: id")
      end

      it "throws for unterminated quoted-string" do
        expect {
          described_class.deserialize('Payment id="a", realm="api", method="tempo", intent="charge", request="e30", description="oops')
        }.to raise_error("Unterminated quoted-string.")
      end

      it "throws for invalid method casing" do
        expect {
          described_class.deserialize('Payment id="a", realm="api", method="Tempo", intent="charge", request="e30"')
        }.to raise_error('Invalid method: "Tempo". Must be lowercase per spec.')
      end

      it "throws for malformed auth-param" do
        expect {
          described_class.deserialize('Payment id="a", realm="api", method="tempo", intent="charge", request="e30", ="value"')
        }.to raise_error("Malformed auth-param.")
      end

      it "throws for missing request parameter" do
        expect {
          described_class.deserialize('Bearer realm="api", Payment id="a", realm="api", method="tempo", intent="charge"')
        }.to raise_error("Missing request parameter.")
      end
    end
  end

  describe ".verify" do
    it "returns true for valid HMAC-bound id" do
      challenge = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "my-secret"
      )
      expect(described_class.verify(challenge, secret_key: "my-secret")).to be true
    end

    it "returns false for wrong secretKey" do
      challenge = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "my-secret"
      )
      expect(described_class.verify(challenge, secret_key: "wrong-secret")).to be false
    end

    it "returns false for tampered challenge" do
      challenge = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, secret_key: "my-secret"
      )
      tampered = challenge.merge(request: { amount: "2000000" })
      expect(described_class.verify(tampered, secret_key: "my-secret")).to be false
    end
  end

  describe "opaque/meta" do
    it "meta sets opaque on challenge via from()" do
      challenge = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000" },
        meta: { pi: "pi_3abc123XYZ" }
      )
      expect(challenge[:opaque]).to eq(pi: "pi_3abc123XYZ")
      expect(challenge[:request][:opaque]).to be_nil
    end

    it "challenge.opaque is nil when no meta" do
      challenge = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000" }
      )
      expect(challenge[:opaque]).to be_nil
    end

    it "opaque roundtrips through serialize/deserialize" do
      original = described_class.from(
        id: "abc123",
        realm: "api.example.com",
        method: "tempo",
        intent: "charge",
        request: { amount: "1000000" },
        meta: { pi: "pi_3abc123XYZ", deposit: "dep_456" }
      )

      header = described_class.serialize(original)
      deserialized = described_class.deserialize(header)
      expect(deserialized[:opaque]).to eq("pi" => "pi_3abc123XYZ", "deposit" => "dep_456")
    end

    it "opaque affects challenge ID" do
      with_meta = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, meta: { pi: "pi_3abc123XYZ" },
        secret_key: "test-secret"
      )
      without_meta = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" },
        secret_key: "test-secret"
      )
      expect(with_meta[:id]).not_to eq(without_meta[:id])
    end

    it "verify succeeds with opaque" do
      challenge = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, meta: { pi: "pi_3abc123XYZ" },
        secret_key: "my-secret"
      )
      expect(described_class.verify(challenge, secret_key: "my-secret")).to be true
    end

    it "verify detects tampered opaque" do
      challenge = described_class.from(
        realm: "api.example.com", method: "tempo", intent: "charge",
        request: { amount: "1000000" }, meta: { pi: "pi_3abc123XYZ" },
        secret_key: "my-secret"
      )
      tampered = challenge.merge(opaque: { pi: "pi_TAMPERED" })
      expect(described_class.verify(tampered, secret_key: "my-secret")).to be false
    end
  end
end
