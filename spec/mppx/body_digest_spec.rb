# frozen_string_literal: true

RSpec.describe Mppx::BodyDigest do
  describe ".compute" do
    it "computes sha-256 digest from string" do
      digest = described_class.compute('{"amount":"1000"}')
      expect(digest).to match(/\Asha-256=/)
      expect(digest).to eq("sha-256=Bxp4xJtbVfsB9npD5AEWUnIk76Cuv8Au4ECDA+F0biY=")
    end

    it "computes sha-256 digest from object" do
      digest = described_class.compute({ "amount" => "1000" })
      expect(digest).to eq("sha-256=Bxp4xJtbVfsB9npD5AEWUnIk76Cuv8Au4ECDA+F0biY=")
    end

    it "same input produces same digest" do
      body = '{"foo":"bar"}'
      digest1 = described_class.compute(body)
      digest2 = described_class.compute(body)
      expect(digest1).to eq(digest2)
    end

    it "different inputs produce different digests" do
      digest1 = described_class.compute('{"a":"1"}')
      digest2 = described_class.compute('{"a":"2"}')
      expect(digest1).not_to eq(digest2)
    end
  end

  describe ".verify" do
    it "returns true for matching digest" do
      body = '{"amount":"1000"}'
      digest = described_class.compute(body)
      expect(described_class.verify(digest, body)).to be true
    end

    it "returns false for non-matching digest" do
      digest = described_class.compute('{"amount":"1000"}')
      expect(described_class.verify(digest, '{"amount":"2000"}')).to be false
    end
  end
end
