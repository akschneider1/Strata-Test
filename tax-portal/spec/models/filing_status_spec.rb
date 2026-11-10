# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FilingStatus do
  def status_for(dependents: 0, **attributes)
    tax_return = create(:tax_return, has_dependents: dependents.positive?, **attributes)
    create_list(:dependent, dependents, tax_return: tax_return)
    described_class.for(tax_return.reload)
  end

  it "is single for an unmarried person with no dependents" do
    expect(status_for(marital_status: "unmarried")).to have_attributes(code: "SINGLE", reason: :single)
  end

  it "is joint or separate for a married person, by their choice" do
    expect(status_for(marital_status: "married", filing_jointly: true).code).to eq("JOINT")
    expect(status_for(marital_status: "married", filing_jointly: false).code).to eq("SEPARATE")
  end

  it "is head of household for an unmarried person who supports a dependent's home" do
    status = status_for(marital_status: "unmarried", dependents: 1, paid_over_half_home_costs: true)

    expect(status).to have_attributes(code: "HEAD_OF_HOUSEHOLD", reason: :head_of_household)
  end

  it "stays single, and says why, when they did not pay most of the home costs" do
    status = status_for(marital_status: "unmarried", dependents: 1, paid_over_half_home_costs: false)

    expect(status).to have_attributes(code: "SINGLE", reason: :single_did_not_pay_home_costs)
  end

  it "is surviving spouse for a recent widow or widower supporting a dependent" do
    expect(status_for(marital_status: "widowed", dependents: 1, paid_over_half_home_costs: true).code).to eq("SURVIVING_SPOUSE")
  end

  it "ignores dependents who did not live with the filer most of the year" do
    tax_return = create(:tax_return, marital_status: "unmarried", has_dependents: true, paid_over_half_home_costs: true)
    create(:dependent, tax_return: tax_return, lived_with_filer_over_half_year: false)

    expect(described_class.for(tax_return.reload).code).to eq("SINGLE")
  end
end
