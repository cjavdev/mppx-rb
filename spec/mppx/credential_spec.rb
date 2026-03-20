# frozen_string_literal: true

RSpec.describe Mppx::Credential do
  let(:challenge) do
    Mppx::Challenge.from(
      id: "x7Tg2pLqR9mKvNwY3hBcZa",
      realm: "api.example.com",
      method: "tempo",
      intent: "charge",
      request: { amount: "1000" }
    )
  end

  describe ".from" do
    it "creates credential" do
      credential = described_class.from(
        challenge: challenge,
        payload: { signature: "0x1234" }
      )

      expect(credential[:challenge][:id]).to eq("x7Tg2pLqR9mKvNwY3hBcZa")
      expect(credential[:payload]).to eq(signature: "0x1234")
    end

    it "creates credential with source" do
      credential = described_class.from(
        challenge: challenge,
        source: "did:pkh:eip155:1:0x1234567890abcdef",
        payload: { hash: "0xabcd" }
      )

      expect(credential[:source]).to eq("did:pkh:eip155:1:0x1234567890abcdef")
      expect(credential[:payload]).to eq(hash: "0xabcd")
    end
  end

  describe ".serialize" do
    it "serializes credential to Authorization header format" do
      credential = described_class.from(
        challenge: challenge,
        payload: { signature: "0x1234" }
      )

      header = described_class.serialize(credential)
      expect(header).to match(/\APayment /)
    end
  end

  describe ".deserialize" do
    it "roundtrip preserves data" do
      original = described_class.from(
        challenge: challenge,
        source: "did:pkh:eip155:1:0x1234567890abcdef",
        payload: { hash: "0xabcd" }
      )

      header = described_class.serialize(original)
      deserialized = described_class.deserialize(header)

      expect(deserialized[:challenge][:id]).to eq(original[:challenge][:id])
      expect(deserialized[:payload]).to eq("hash" => "0xabcd")
      expect(deserialized[:source]).to eq(original[:source])
    end

    it "throws for missing Payment scheme" do
      expect { described_class.deserialize("Bearer abc123") }.to raise_error("Missing Payment scheme.")
    end

    it "throws for invalid base64url" do
      expect { described_class.deserialize("Payment !!invalid!!") }.to raise_error("Invalid base64url or JSON.")
    end
  end

  describe ".extract_payment_scheme" do
    it "finds Payment scheme in multi-scheme header" do
      credential = described_class.from(
        challenge: challenge,
        payload: { signature: "0x1234" }
      )
      header = described_class.serialize(credential)
      combined = "Bearer some-jwt-token, #{header}"
      result = described_class.extract_payment_scheme(combined)
      expect(result).to match(/\APayment /)
    end

    it "returns nil when no Payment scheme" do
      result = described_class.extract_payment_scheme("Bearer some-jwt-token")
      expect(result).to be_nil
    end
  end
end
