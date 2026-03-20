# frozen_string_literal: true

RSpec.describe Mppx::ConstantTimeEqual do
  describe ".call" do
    it "returns true for identical strings" do
      expect(described_class.call("abc", "abc")).to be true
    end

    it "returns true for empty strings" do
      expect(described_class.call("", "")).to be true
    end

    it "returns false for different strings of same length" do
      expect(described_class.call("abc", "abd")).to be false
    end

    it "returns false for different lengths" do
      expect(described_class.call("abc", "abcd")).to be false
      expect(described_class.call("abcd", "abc")).to be false
    end

    it "returns false for empty vs non-empty" do
      expect(described_class.call("", "a")).to be false
      expect(described_class.call("a", "")).to be false
    end

    it "returns false when only first character differs" do
      expect(described_class.call("xbc", "abc")).to be false
    end

    it "returns false when only last character differs" do
      expect(described_class.call("abx", "abc")).to be false
    end

    it "handles base64url strings (typical HMAC output)" do
      a = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
      b = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
      expect(described_class.call(a, b)).to be true
    end

    it "detects single-bit difference in base64url strings" do
      a = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
      b = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXl"
      expect(described_class.call(a, b)).to be false
    end
  end
end
