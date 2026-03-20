# frozen_string_literal: true

RSpec.describe Mppx::Expires do
  let(:fixed_time) { Time.utc(2025, 6, 15, 12, 0, 0) }

  before do
    allow(Time).to receive(:now).and_return(fixed_time)
  end

  describe ".seconds" do
    it "returns ISO string n seconds from now" do
      expect(described_class.seconds(30)).to eq("2025-06-15T12:00:30.000Z")
    end

    it "0 returns current time" do
      expect(described_class.seconds(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.seconds(-60)).to eq("2025-06-15T11:59:00.000Z")
    end
  end

  describe ".minutes" do
    it "returns ISO string n minutes from now" do
      expect(described_class.minutes(5)).to eq("2025-06-15T12:05:00.000Z")
    end

    it "0 returns current time" do
      expect(described_class.minutes(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.minutes(-10)).to eq("2025-06-15T11:50:00.000Z")
    end
  end

  describe ".hours" do
    it "returns ISO string n hours from now" do
      expect(described_class.hours(2)).to eq("2025-06-15T14:00:00.000Z")
    end

    it "0 returns current time" do
      expect(described_class.hours(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.hours(-3)).to eq("2025-06-15T09:00:00.000Z")
    end
  end

  describe ".days" do
    it "returns ISO string n days from now" do
      expect(described_class.days(1)).to eq("2025-06-16T12:00:00.000Z")
    end

    it "0 returns current time" do
      expect(described_class.days(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.days(-2)).to eq("2025-06-13T12:00:00.000Z")
    end
  end

  describe ".weeks" do
    it "returns ISO string n weeks from now" do
      expect(described_class.weeks(1)).to eq("2025-06-22T12:00:00.000Z")
    end

    it "0 returns current time" do
      expect(described_class.weeks(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.weeks(-1)).to eq("2025-06-08T12:00:00.000Z")
    end
  end

  describe ".months" do
    it "returns ISO string n months (30 days) from now" do
      expect(described_class.months(1)).to eq("2025-07-15T12:00:00.000Z")
    end

    it "0 returns current time" do
      expect(described_class.months(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.months(-1)).to eq("2025-05-16T12:00:00.000Z")
    end
  end

  describe ".years" do
    it "returns ISO string n years (365 days) from now" do
      expect(described_class.years(1)).to eq("2026-06-15T12:00:00.000Z")
    end

    it "0 returns current time" do
      expect(described_class.years(0)).to eq("2025-06-15T12:00:00.000Z")
    end

    it "negative n returns past time" do
      expect(described_class.years(-1)).to eq("2024-06-15T12:00:00.000Z")
    end
  end
end
