# frozen_string_literal: true

# Made-up people for demonstrating the prototype. Social Security numbers use
# area 000, which the SSA never issues, so they can't belong to anyone.
#
# Each visitor gets their own copy of these people (see DemoSpace):
#
#   DemoSpace.start!   # a new copy, with everyone in their starting state
#
# Never runs in production.
class DemoData
  ADDRESS = { mailing_address_street_line_1: "1375 Sherman St", mailing_address_city: "Denver", mailing_address_state: "CO", mailing_address_zip_code: "80261" }.freeze

  PEOPLE = {
    maya: { name: %w[Maya Torres], born: Date.new(1996, 3, 14), ssn: "000001001" },
    daniela: { name: %w[Daniela Ruiz], born: Date.new(1991, 8, 2), ssn: "000001002" },
    walter: { name: %w[Walter Bennett], born: Date.new(1957, 5, 20), ssn: "000001003" },
    jordan: { name: %w[Jordan Lee], born: Date.new(1984, 11, 9), ssn: "000001004" },
    elena: { name: %w[Elena Park], born: Date.new(1988, 4, 22), ssn: "000001006" }
  }.freeze
  ELEANOR_SSN = "000001005"

  WAGE_RECORDS = [
    { ssn: "000001001", kind: "w2", payer_name: "Front Range Outfitters", amount: 48_000, colorado_withholding: 1_650 },
    { ssn: "000001002", kind: "w2", payer_name: "Mile High Community Clinic", amount: 38_000, colorado_withholding: 900 },
    { ssn: "000001003", kind: "form_1099r", payer_name: "Colorado PERA", amount: 31_000, colorado_withholding: 600 },
    { ssn: "000001003", kind: "ssa_1099", payer_name: "Social Security Administration", amount: 24_000, colorado_withholding: 0 },
    { ssn: ELEANOR_SSN, kind: "form_1099r", payer_name: "Rocky Mountain Teachers Retirement", amount: 12_000, colorado_withholding: 0 },
    { ssn: ELEANOR_SSN, kind: "ssa_1099", payer_name: "Social Security Administration", amount: 18_000, colorado_withholding: 0 },
    { ssn: "000001004", kind: "w2", payer_name: "Summit Logistics", amount: 61_000, colorado_withholding: 2_900 },
    { ssn: "000001004", kind: "form_1099g", payer_name: "Colorado Department of Labor and Employment", amount: 5_200, colorado_withholding: 0 },
    { ssn: "000001006", kind: "w2", payer_name: "Pikes Peak Design", amount: 72_000, colorado_withholding: 1_500 }
  ].freeze

  # The examiners in every copy of the demo.
  EXAMINERS = { examiner: "Priya Shah", examiner2: "Marcus Reed" }.freeze

  # A demo person's sign-in id. Each copy of the demo has its own people.
  def self.uid(key, space)
    space ? "demo-#{space.id}-#{key}" : "demo-#{key}"
  end

  # `space` is the visitor's copy of the demo (a DemoSpace) these people
  # belong to.
  def initialize(space = nil)
    @space = space
  end

  # Creates the demo people in their starting state.
  def load!
    raise "Demo data can't be loaded in production" if Rails.env.production?

    users = PEOPLE.to_h { |key, person| [ key, create_user(key, person[:name].join(" "), :taxpayer) ] }
    EXAMINERS.each { |key, name| create_user(key, name, :examiner) }
    WAGE_RECORDS.each { |record| WageRecord.create!(record.merge(tax_year: TaxReturn::CURRENT_TAX_YEAR, demo_space_id: @space&.id)) }

    # Maya starts from nothing: she is the live "file a return" demo.
    # Daniela has answered everything and is ready to review and sign.
    daniela(users[:daniela])
    # Walter and Eleanor have filed; their return was accepted automatically.
    submit(walter(users[:walter]))
    # Elena has filed too. Her employer took too little out of her pay, so
    # she owes: the only demo person who does.
    submit(elena(users[:elena]))
    # Jordan has filed with more withholding than his employer reported, so
    # his return is waiting for an examiner.
    submit(jordan(users[:jordan]))
    users
  end

  # Builders are public so tests can reuse the same households.

  # Maya as she will be once she has answered everything. The demo starts
  # her with nothing; this is used to warm up the tax engine for her return.
  def maya(user)
    finish_income(start(user, :maya, marital_status: "unmarried", has_dependents: false))
  end

  def daniela(user)
    tax_return = start(user, :daniela, marital_status: "unmarried", has_dependents: true)
    tax_return.dependents.create!(name_first: "Mateo", name_last: "Ruiz", date_of_birth: Date.new(2021, 6, 12), relationship: "child", ssn: "000002001")
    tax_return.dependents.create!(name_first: "Lucia", name_last: "Ruiz", date_of_birth: Date.new(2016, 2, 3), relationship: "child", ssn: "000002002")
    tax_return.update!(paid_over_half_home_costs: true, paid_childcare: true, childcare_expenses: 4_200)
    finish_income(tax_return)
  end

  def walter(user)
    tax_return = start(
      user, :walter, marital_status: "married", filing_jointly: true, has_dependents: false,
      spouse_name_first: "Eleanor", spouse_name_last: "Bennett", spouse_date_of_birth: Date.new(1959, 9, 30), spouse_ssn: ELEANOR_SSN
    )
    finish_income(tax_return, has_interest_income: true, taxable_interest: 1_400)
  end

  def elena(user)
    finish_income(start(user, :elena, marital_status: "unmarried", has_dependents: false))
  end

  def jordan(user)
    tax_return = start(user, :jordan, marital_status: "unmarried", has_dependents: false)
    finish_income(tax_return) do |documents|
      # Jordan types 3,900 from a pay stub; his employer reported 2,900.
      documents.find { |document| document.kind == "w2" }.correct!(colorado_withholding: 3_900)
    end
  end

  def submit(tax_return)
    tax_return.assign_attributes(declaration_accepted: true, signature_name: tax_return.filer_full_name)
    tax_return.submit_application || raise("Could not submit demo return: #{tax_return.errors.full_messages.to_sentence}")
    # Don't wait for the background job: process it here and now.
    ProcessReturnJob.perform_now(tax_return.tax_return_case.id)
    raise "Demo return was not processed. Is the tax engine running?" if tax_return.tax_return_case.reload.processing_stalled?

    tax_return
  end

  private

  def create_user(key, full_name, role)
    suffix = @space ? "+#{@space.id}" : ""
    User.create!(
      uid: self.class.uid(key, @space), provider: "demo", email: "#{key}#{suffix}@demo.example",
      full_name: full_name, role: role, mfa_preference: :opt_out, demo_space_id: @space&.id
    )
  end

  def start(user, key, **attributes)
    person = PEOPLE.fetch(key)
    TaxReturn.create!(
      user: user, filer_name_first: person[:name].first, filer_name_last: person[:name].last,
      filer_date_of_birth: person[:born], filer_ssn: person[:ssn], full_year_resident: true, **ADDRESS, **attributes
    )
  end

  def finish_income(tax_return, has_interest_income: false, taxable_interest: nil)
    documents = RecordsOnFile.prefill(tax_return)
    documents.each(&:confirm!)
    yield documents if block_given?
    tax_return.update!(
      income_documents_reviewed: true, has_interest_income: has_interest_income, taxable_interest: taxable_interest, has_other_income: false,
      refund_method: "direct_deposit", bank_account_type: "checking", bank_routing_number: "102000021", bank_account_number: "000123456789"
    )
    tax_return
  end
end
