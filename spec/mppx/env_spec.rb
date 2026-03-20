# frozen_string_literal: true

RSpec.describe Mppx::Env do
  around do |example|
    # Save and clear env vars
    saved = {}
    all_vars = Mppx::Env::VARIABLES.values.flatten
    all_vars.each do |name|
      saved[name] = ENV[name]
      ENV.delete(name)
    end

    example.run

    # Restore env vars
    saved.each do |name, value|
      if value
        ENV[name] = value
      else
        ENV.delete(name)
      end
    end
  end

  describe ".get(:realm)" do
    it "returns default realm when no env vars are set" do
      expect(described_class.get(:realm)).to eq("MPP Payment")
    end

    it "returns FLY_APP_NAME when set" do
      ENV["FLY_APP_NAME"] = "my-fly-app"
      expect(described_class.get(:realm)).to eq("my-fly-app")
    end

    it "FLY_APP_NAME takes precedence over HOST" do
      ENV["FLY_APP_NAME"] = "fly-app"
      ENV["HOST"] = "my-host"
      expect(described_class.get(:realm)).to eq("fly-app")
    end

    it "HOST takes precedence over MPP_REALM" do
      ENV["HOST"] = "my-host"
      ENV["MPP_REALM"] = "custom-realm"
      expect(described_class.get(:realm)).to eq("my-host")
    end

    it "falls through to later vars when earlier ones are unset" do
      ENV["MPP_REALM"] = "fallback-realm"
      expect(described_class.get(:realm)).to eq("fallback-realm")
    end
  end

  describe ".get(:secret_key)" do
    it "returns nil when MPP_SECRET_KEY is not set" do
      expect(described_class.get(:secret_key)).to be_nil
    end

    it "returns MPP_SECRET_KEY when set" do
      ENV["MPP_SECRET_KEY"] = "sk_live_abc123"
      expect(described_class.get(:secret_key)).to eq("sk_live_abc123")
    end
  end
end
