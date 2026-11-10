# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxReturn do
  describe "starting a return" do
    it "opens a case at the filing step" do
      tax_return = create(:tax_return)

      expect(tax_return.tax_return_case.step).to eq("file_return")
    end

    it "allows one return per person per tax year" do
      tax_return = create(:tax_return)

      expect { create(:tax_return, user: tax_return.user) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "sensitive data" do
    it "encrypts Social Security and bank account numbers at rest" do
      tax_return = create(:tax_return, filer_ssn: "000-12-3456", bank_account_number: "000111222333")
      stored = described_class.connection.select_one("SELECT filer_ssn, bank_account_number FROM tax_returns WHERE id = '#{tax_return.id}'")

      expect(tax_return.reload.filer_ssn).to eq("000123456")
      expect(stored["filer_ssn"]).not_to include("000123456")
      expect(stored["bank_account_number"]).not_to include("000111222333")
    end
  end

  describe "interview pages" do
    let(:tax_return) { create(:tax_return) }

    it "asks about home costs only when it could change the filing status" do
      tax_return.update!(marital_status: "unmarried", has_dependents: true)
      expect(tax_return.ask_home_costs?).to be(false)

      create(:dependent, tax_return: tax_return)
      expect(tax_return.reload.ask_home_costs?).to be(true)

      tax_return.update!(marital_status: "married")
      expect(tax_return.ask_home_costs?).to be(false)
    end

    it "asks about child care only when a dependent is under 13 or disabled" do
      tax_return.update!(has_dependents: true)
      teen = create(:dependent, tax_return: tax_return, date_of_birth: Date.new(2010, 1, 1))
      expect(tax_return.reload.ask_childcare?).to be(false)

      teen.update!(disabled: true)
      expect(tax_return.reload.ask_childcare?).to be(true)
    end

    it "does not treat unanswered confirmations as accepted" do
      expect(tax_return.valid?(:income_documents)).to be(false)
      expect(tax_return.errors[:income_documents_reviewed]).to eq([ "Check the box when you've checked every form" ])
    end

    it "requires every form on file to be reviewed" do
      tax_return = create(:tax_return, :complete)
      create(:wage_record, ssn: tax_return.filer_ssn, kind: "form_1099g", payer_name: "CDLE", amount: 900, colorado_withholding: 0)
      RecordsOnFile.prefill(tax_return)

      expect(tax_return.valid?(:income_documents)).to be(false)
      expect(tax_return.errors.of_kind?(:income_documents_reviewed, :review_each_form)).to be(true)
    end

    it "explains that part-year residents and other income are out of scope" do
      tax_return.full_year_resident = false
      tax_return.has_other_income = true

      expect(tax_return.valid?(:residency)).to be(false)
      expect(tax_return.valid?(:other_income)).to be(false)
    end

    it "writes error messages as full sentences without the field name" do
      tax_return.valid?(:filer_name)

      expect(tax_return.errors.full_messages).to include("Enter your first name")
    end
  end

  describe "#section_state" do
    it "ignores pages that do not apply, so an untouched section is not started" do
      tax_return = create(:tax_return, :complete)
      family = tax_return.flow.tasks.find { |task| task.name == :family }
      tax_return.update_columns(marital_status: nil, has_dependents: nil)

      expect(tax_return.reload.section_state(family)).to eq(:not_started)
    end

    it "reports completed sections and blocks ones whose dependencies are not met" do
      tax_return = create(:tax_return)
      about_you, family = tax_return.flow.tasks.first(2)

      expect(tax_return.section_state(about_you)).to eq(:not_started)
      expect(tax_return.section_state(family)).to eq(:cannot_start_yet)
      expect(create(:tax_return, :complete).then { |complete| complete.section_state(complete.flow.tasks.first) }).to eq(:completed)
    end
  end

  describe "#calculate!" do
    it "stores the result and reuses it until the facts change" do
      tax_return = create(:tax_return, :complete)
      client = TaxEngine::FakeClient.new
      allow(client).to receive(:calculate).and_call_original

      first = tax_return.calculate!(client: client)
      tax_return.calculate!(client: client)
      expect(client).to have_received(:calculate).once
      # (48,000 - 15,750) x 4.4% = 1,419 tax; 1,650 withheld
      expect(first.refund).to eq(231)

      tax_return.update!(has_interest_income: true, taxable_interest: 1_000)
      expect(tax_return.calculate!(client: client).refund).to eq(187)
    end
  end

  describe "submitting" do
    it "needs the declaration and a signature matching the filer's name" do
      tax_return = create(:tax_return, :complete)
      tax_return.assign_attributes(declaration_accepted: nil, signature_name: "Someone Else")

      expect(tax_return.submit_application).to be(false)
      expect(tax_return.errors.attribute_names).to contain_exactly(:declaration_accepted, :signature_name)
    end

    it "assigns a confirmation number and locks the return" do
      tax_return = create(:tax_return, :submitted)

      expect(tax_return.confirmation_number).to match(/\ACO-2025-[A-Z0-9]{8}\z/)
      expect(tax_return.update(phone: "3035550100")).to be(false)
    end
  end
end
