# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxEngine::Facts do
  it "maps a return to the tax engine's request" do
    tax_return = create(:tax_return, :complete, marital_status: "married", filing_jointly: true,
      spouse_name_first: "Sam", spouse_name_last: "Payer", spouse_date_of_birth: Date.new(1960, 1, 1), spouse_ssn: "000990001",
      has_interest_income: true, taxable_interest: 300, has_dependents: true, paid_childcare: true, childcare_expenses: 2_000)
    create(:dependent, tax_return: tax_return, date_of_birth: Date.new(2020, 5, 5))
    create(:wage_record, ssn: "000990001", kind: "ssa_1099", payer_name: "SSA", amount: 20_000, colorado_withholding: 0)
    RecordsOnFile.prefill(tax_return).each(&:confirm!)

    expect(described_class.from_tax_return(tax_return.reload).to_h).to eq(
      "tax_year" => 2025,
      "filing_status" => "JOINT",
      "filer" => { "age" => 35, "wages" => 48_000, "unemployment_compensation" => 0, "pension_income" => 0, "social_security" => 0 },
      "spouse" => { "age" => 65, "wages" => 0, "unemployment_compensation" => 0, "pension_income" => 0, "social_security" => 20_000 },
      "dependents" => [ { "age" => 5, "is_full_time_student" => false, "is_disabled" => false } ],
      "taxable_interest" => 300,
      "childcare_expenses" => 2_000,
      "colorado_tax_withheld" => 1_650
    )
  end

  it "leaves disputed and unreviewed forms off the return" do
    tax_return = create(:tax_return, :complete)
    tax_return.income_documents.first.dispute!

    facts = described_class.from_tax_return(tax_return.reload)
    expect(facts.to_h["filer"]["wages"]).to eq(0)
    expect(facts.to_h["colorado_tax_withheld"]).to eq(0)
  end

  it "applies examiner adjustments without changing the original" do
    facts = described_class.new("filer" => { "wages" => 100 }, "colorado_tax_withheld" => 50)
    adjusted = facts.with_adjustments("filer_wages" => 200, "colorado_tax_withheld" => 10)

    expect(adjusted.value("filer_wages")).to eq(200)
    expect(adjusted.value("colorado_tax_withheld")).to eq(10)
    expect(facts.value("filer_wages")).to eq(100)
    expect(adjusted.digest).not_to eq(facts.digest)
  end
end
