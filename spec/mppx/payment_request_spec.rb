# frozen_string_literal: true

RSpec.describe Mppx::PaymentRequest do
  describe ".from" do
    it "creates a request" do
      request = described_class.from(
        amount: "1000000",
        currency: "USD",
        recipient: "0x1234"
      )
      expect(request).to eq(amount: "1000000", currency: "USD", recipient: "0x1234")
    end
  end

  describe ".serialize" do
    it "serializes request to base64url" do
      request = { amount: "1000000", currency: "USD" }
      serialized = described_class.serialize(request)
      expect(serialized).to match(/\A[A-Za-z0-9_-]+\z/)
      expect(serialized).not_to include("=")
      expect(serialized).not_to include("+")
      expect(serialized).not_to include("/")
    end
  end

  describe ".deserialize" do
    it "deserializes base64url to request" do
      original = { "amount" => "500", "currency" => "EUR" }
      serialized = described_class.serialize(original)
      result = described_class.deserialize(serialized)
      expect(result).to eq("amount" => "500", "currency" => "EUR")
    end

    it "handles special characters in values" do
      original = { "amount" => "1000000", "description" => "Payment for cafe & mas" }
      serialized = described_class.serialize(original)
      result = described_class.deserialize(serialized)
      expect(result["description"]).to eq("Payment for cafe & mas")
    end
  end

  describe "roundtrip" do
    it "roundtrips correctly" do
      original = { "amount" => "1000000", "currency" => "USD", "recipient" => "0x742d35Cc" }
      serialized = described_class.serialize(original)
      deserialized = described_class.deserialize(serialized)
      expect(deserialized).to eq(original)
    end
  end
end
