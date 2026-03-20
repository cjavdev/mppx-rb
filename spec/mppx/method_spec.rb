# frozen_string_literal: true

RSpec.describe Mppx::Method do
  describe ".from" do
    it "creates method" do
      method = described_class.from(
        name: "tempo",
        intent: "charge",
        schema: {
          credential: {
            payload: ->(p) { p }
          },
          request: ->(r) { r }
        }
      )

      expect(method[:name]).to eq("tempo")
      expect(method[:intent]).to eq("charge")
      expect(method[:schema]).to be_a(Hash)
    end
  end

  describe ".to_server" do
    it "extends method with verify function" do
      method = described_class.from(
        name: "tempo",
        intent: "charge",
        schema: {
          credential: { payload: ->(p) { p } },
          request: ->(r) { r }
        }
      )

      server_method = described_class.to_server(
        method,
        verify: ->(credential:, request:) {
          { method: "tempo", reference: "tx-123", status: "success", timestamp: Time.now.utc.iso8601(3) }
        }
      )

      expect(server_method[:verify]).to be_a(Proc)
      expect(server_method[:name]).to eq("tempo")
    end
  end
end
