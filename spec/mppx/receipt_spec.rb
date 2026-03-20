# frozen_string_literal: true

RSpec.describe Mppx::Receipt do
  describe ".from" do
    it "creates receipt with success status" do
      receipt = described_class.from(
        method: "tempo",
        reference: "0x1234",
        status: "success",
        timestamp: "2025-01-21T12:00:00.000Z"
      )

      expect(receipt[:method]).to eq("tempo")
      expect(receipt[:reference]).to eq("0x1234")
      expect(receipt[:status]).to eq("success")
      expect(receipt[:timestamp]).to eq("2025-01-21T12:00:00.000Z")
    end

    it "rejects receipt with failed status" do
      expect {
        described_class.from(
          method: "tempo",
          reference: "0xabcd",
          status: "failed",
          timestamp: "2025-01-21T13:00:00.000Z"
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe ".serialize" do
    it "serializes receipt to base64url" do
      receipt = described_class.from(
        method: "tempo",
        reference: "0x1234",
        status: "success",
        timestamp: "2025-01-21T12:00:00.000Z"
      )

      header = described_class.serialize(receipt)
      expect(header).to match(/\A[A-Za-z0-9_-]+\z/)
    end
  end

  describe ".deserialize" do
    it "deserializes base64url to receipt" do
      receipt = described_class.from(
        method: "tempo",
        reference: "0x1234",
        status: "success",
        timestamp: "2025-01-21T12:00:00.000Z"
      )

      encoded = described_class.serialize(receipt)
      deserialized = described_class.deserialize(encoded)

      expect(deserialized[:method]).to eq("tempo")
      expect(deserialized[:reference]).to eq("0x1234")
      expect(deserialized[:status]).to eq("success")
      expect(deserialized[:timestamp]).to eq("2025-01-21T12:00:00.000Z")
    end
  end

  describe ".from_response" do
    it "extracts receipt from Payment-Receipt header" do
      receipt = described_class.from(
        method: "tempo",
        reference: "0x1234",
        status: "success",
        timestamp: "2025-01-21T12:00:00.000Z"
      )
      encoded = described_class.serialize(receipt)
      headers = { "Payment-Receipt" => encoded }

      result = described_class.from_response(headers)
      expect(result[:method]).to eq("tempo")
      expect(result[:status]).to eq("success")
    end

    it "throws when Payment-Receipt header is missing" do
      expect { described_class.from_response({}) }.to raise_error("Missing Payment-Receipt header.")
    end
  end
end
