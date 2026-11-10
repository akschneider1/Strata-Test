# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dependent do
  let(:tax_return) { create(:tax_return, :complete) }

  def person(born:, relationship: "child", lived_with: true, **attributes)
    build(:dependent, tax_return: tax_return, date_of_birth: born, relationship: relationship, lived_with_filer_over_half_year: lived_with, **attributes)
  end

  describe "who counts as a dependent" do
    it "counts a child under 19 who lived with the filer" do
      child = person(born: Date.new(2007, 1, 1))

      expect(child).to have_attributes(age_at_year_end: 18, qualifying_child?: true, qualifies?: true, qualification: :qualifying_child)
      expect(child.needs_support_questions?).to be(false)
    end

    it "counts a 19 to 23 year old only if they are a full-time student" do
      expect(person(born: Date.new(2002, 1, 1), full_time_student: true).qualifying_child?).to be(true)
      expect(person(born: Date.new(2002, 1, 1)).qualifying_child?).to be(false)
      expect(person(born: Date.new(2001, 1, 1), full_time_student: true).qualifying_child?).to be(false)
    end

    it "counts a permanently disabled child at any age" do
      expect(person(born: Date.new(1990, 1, 1), disabled: true).qualifying_child?).to be(true)
    end

    it "does not count an adult child without asking about income and support" do
      adult = person(born: Date.new(1990, 5, 5))

      expect(adult).to have_attributes(qualifies?: false, needs_support_questions?: true, support_questions_answered?: false, qualification: :needs_answers)
    end

    it "counts an adult relative with little income whom the filer supports" do
      expect(person(born: Date.new(1990, 5, 5), income_under_limit: true, supported_by_filer: true)).to have_attributes(qualifies?: true, qualification: :qualifying_relative)
      expect(person(born: Date.new(1990, 5, 5), income_under_limit: false, supported_by_filer: true)).to have_attributes(qualifies?: false, qualification: :income_too_high)
      expect(person(born: Date.new(1990, 5, 5), income_under_limit: true, supported_by_filer: false)).to have_attributes(qualifies?: false, qualification: :not_supported_by_you)
    end

    it "lets a supported parent count without living with the filer, but nobody else" do
      parent = person(born: Date.new(1950, 1, 1), relationship: "parent", lived_with: false, income_under_limit: true, supported_by_filer: true)
      cousin = person(born: Date.new(1950, 1, 1), relationship: "other_relative", lived_with: false, income_under_limit: true, supported_by_filer: true)

      expect(parent.qualifies?).to be(true)
      expect(cousin).to have_attributes(qualifies?: false, qualification: :did_not_live_with_you, needs_support_questions?: false)
    end
  end

  describe "Social Security numbers" do
    it "can't be the filer's or the spouse's" do
      tax_return.update!(spouse_ssn: "000007777")

      own = person(born: Date.new(2015, 1, 1), ssn: tax_return.filer_ssn)
      spouses = person(born: Date.new(2015, 1, 1), ssn: "000-00-7777")

      expect(own).not_to be_valid
      expect(own.errors[:ssn]).to include("Enter this person's own number. This one is yours.")
      expect(spouses).not_to be_valid
      expect(spouses.errors[:ssn]).to include("Enter this person's own number. This one is your spouse's.")
    end

    it "stops a spouse from sharing a dependent's number" do
      create(:dependent, tax_return: tax_return, ssn: "000008888", lived_with_filer_over_half_year: true)
      tax_return.assign_attributes(
        marital_status: "married", filing_jointly: true, spouse_name_first: "Sam", spouse_name_last: "Lee",
        spouse_date_of_birth: Date.new(1990, 1, 1), spouse_ssn: "000008888"
      )

      expect(tax_return.valid?(TaxReturn::Flow::SPOUSE)).to be(false)
      expect(tax_return.errors[:spouse_ssn]).to include("Enter your spouse's number. This one belongs to a dependent you added.")
    end
  end

  describe "filing status" do
    it "does not give head of household for an adult child who doesn't qualify" do
      tax_return.update!(has_dependents: true, paid_over_half_home_costs: true)
      adult = create(:dependent, tax_return: tax_return, date_of_birth: Date.new(1990, 5, 5), lived_with_filer_over_half_year: true)
      expect(tax_return.reload.filing_status.code).to eq("SINGLE")

      adult.update!(income_under_limit: true, supported_by_filer: true)
      expect(tax_return.reload.filing_status.code).to eq("HEAD_OF_HOUSEHOLD")
    end
  end
end
