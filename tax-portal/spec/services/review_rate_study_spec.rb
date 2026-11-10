# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewRateStudy do
  it "files a made-up population through the checks and leaves nothing behind" do
    result = described_class.new(returns: 40, seed: 7).run

    expect(result.returns).to eq(40)
    expect(result.by_household.values.sum).to eq(40)
    expect(result.flagged).to be_between(0, 40)
    expect(result.by_code.keys - ReviewFlag::CODES).to be_empty
    expect(TaxReturn.count).to eq(0)
    expect(User.where(provider: "study").count).to eq(0)
  end

  it "gives the same answer for the same seed" do
    first = described_class.new(returns: 25, seed: 3).run
    second = described_class.new(returns: 25, seed: 3).run

    expect(second.by_code).to eq(first.by_code)
    expect(second.by_household).to eq(first.by_household)
  end

  it "flags more returns when taxpayers differ from the records more often" do
    config = YAML.load_file(described_class::CONFIG_PATH)
    config["behavior"]["overstates_withholding"] = 1.0

    result = described_class.new(returns: 20, seed: 5, config: config).run

    expect(result.by_code["withholding_higher_than_record"]).to be >= 14
  end
end
