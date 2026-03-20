# frozen_string_literal: true

RSpec.describe Mppx::Store do
  describe ".memory" do
    let(:store) { described_class.memory }

    it "roundtrip" do
      nested = { "name" => "alice", "scores" => [1, 2, 3], "meta" => { "active" => true, "tags" => %w[a b] } }
      store[:put].call("k", nested)
      expect(store[:get].call("k")).to eq(nested)
    end

    it "get missing key returns nil" do
      expect(store[:get].call("missing")).to be_nil
    end

    it "delete removes key" do
      store[:put].call("k", "value")
      store[:delete].call("k")
      expect(store[:get].call("k")).to be_nil
    end

    it "put overwrites existing value" do
      store[:put].call("k", "first")
      store[:put].call("k", "second")
      expect(store[:get].call("k")).to eq("second")
    end

    it "json-roundtrips nested objects" do
      value = { "a" => [1, { "b" => "c" }], "d" => nil }
      store[:put].call("k", value)
      expect(store[:get].call("k")).to eq(value)
    end
  end
end
