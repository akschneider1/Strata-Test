# frozen_string_literal: true

# A Colorado individual income tax return (form DR 0104) as the taxpayer
# fills it in. Once submitted it cannot be changed (Strata::ApplicationForm);
# examiner changes are recorded separately as ReturnAdjustments on the case.
class TaxReturn < Strata::ApplicationForm
  include Strata::Flows::ApplicationFormValidations
  include Strata::Auditable

  CURRENT_TAX_YEAR = 2025
  MARITAL_STATUSES = %w[unmarried married widowed].freeze
  REFUND_METHODS = %w[direct_deposit check].freeze
  BANK_ACCOUNT_TYPES = %w[checking savings].freeze
  # The Social Security Administration never issues numbers in these ranges,
  # so real SSNs always pass and demo data can use them safely.
  SSN_FORMAT = /\A\d{9}\z/
  MAX_AMOUNT = 9_999_999

  belongs_to :user
  has_many :dependents, dependent: :destroy
  has_many :income_documents, dependent: :destroy
  has_one :tax_return_case, foreign_key: :application_form_id, inverse_of: :tax_return, dependent: :destroy

  strata_attribute :filer_name, :name
  strata_attribute :filer_date_of_birth, :memorable_date
  strata_attribute :mailing_address, :address
  strata_attribute :spouse_name, :name
  strata_attribute :spouse_date_of_birth, :memorable_date

  encrypts :filer_ssn, deterministic: true
  encrypts :spouse_ssn, deterministic: true
  encrypts :bank_account_number

  normalizes :filer_ssn, :spouse_ssn, with: ->(value) { value.to_s.gsub(/\D/, "").presence }
  normalizes :bank_routing_number, :bank_account_number, with: ->(value) { value.to_s.gsub(/\s/, "").presence }

  attribute :tax_year, :integer, default: CURRENT_TAX_YEAR

  validate_flow TaxReturnFlow

  validates :tax_year, inclusion: { in: [ CURRENT_TAX_YEAR ] }

  # About you
  validates :filer_name_first, :filer_name_last, presence: true, on: Flow::FILER_NAME
  validates :filer_date_of_birth, presence: true, on: Flow::FILER_IDENTITY
  validate :filer_must_be_adult, on: Flow::FILER_IDENTITY
  validates :filer_ssn, presence: true, format: { with: SSN_FORMAT, message: :invalid_ssn, allow_blank: true }, on: Flow::FILER_IDENTITY
  validates :mailing_address_street_line_1, :mailing_address_city, :mailing_address_state, presence: true, on: Flow::CONTACT
  validates :mailing_address_zip_code, format: { with: /\A\d{5}(-\d{4})?\z/, message: :invalid_zip }, on: Flow::CONTACT
  validates :full_year_resident, inclusion: { in: [ true, false ], message: :choose_one }, on: Flow::RESIDENCY
  validates :full_year_resident, acceptance: { accept: true, message: :part_year_not_supported, allow_nil: true }, on: Flow::RESIDENCY

  # Family
  validates :marital_status, inclusion: { in: MARITAL_STATUSES, message: :choose_one }, on: Flow::MARITAL_STATUS
  validates :filing_jointly, inclusion: { in: [ true, false ], message: :choose_one }, on: Flow::FILING_JOINTLY, if: :married?
  with_options on: Flow::SPOUSE, if: :joint? do
    validates :spouse_name_first, :spouse_name_last, :spouse_date_of_birth, presence: true
    validates :spouse_ssn, presence: true, format: { with: SSN_FORMAT, message: :invalid_ssn, allow_blank: true }
    validate :spouse_ssn_differs_from_filer
  end
  validates :has_dependents, inclusion: { in: [ true, false ], message: :choose_one }, on: Flow::DEPENDENTS
  validate :dependents_listed, on: Flow::DEPENDENTS
  validates :paid_over_half_home_costs, inclusion: { in: [ true, false ], message: :choose_one }, on: Flow::HOME_COSTS, if: :ask_home_costs?
  with_options on: Flow::CHILDCARE, if: :ask_childcare? do
    validates :paid_childcare, inclusion: { in: [ true, false ], message: :choose_one }
    validates :childcare_expenses, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_AMOUNT, allow_blank: true }, if: :paid_childcare
  end

  # Income
  validates :income_documents_reviewed, acceptance: { accept: true, message: :confirm_income_documents }, on: Flow::INCOME_DOCUMENTS
  validate :every_income_document_reviewed, on: Flow::INCOME_DOCUMENTS
  validates :has_interest_income, inclusion: { in: [ true, false ], message: :choose_one }, on: Flow::INTEREST
  validates :taxable_interest, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_AMOUNT, allow_blank: true }, on: Flow::INTEREST, if: :has_interest_income
  validates :has_other_income, inclusion: { in: [ true, false ], message: :choose_one }, on: Flow::OTHER_INCOME
  validates :has_other_income, acceptance: { accept: false, message: :other_income_not_supported, allow_nil: true }, on: Flow::OTHER_INCOME

  # Refund
  validates :refund_method, inclusion: { in: REFUND_METHODS, message: :choose_one }, on: Flow::REFUND_METHOD
  with_options on: Flow::REFUND_METHOD, if: :direct_deposit? do
    validates :bank_account_type, inclusion: { in: BANK_ACCOUNT_TYPES, message: :choose_one }
    validates :bank_routing_number, format: { with: /\A\d{9}\z/, message: :invalid_routing_number }
    validates :bank_account_number, format: { with: /\A\d{4,17}\z/, message: :invalid_account_number }
  end

  # Signature
  validates :declaration_accepted, acceptance: { accept: true, message: :accept_declaration }, on: :submit
  validates :signature_name, presence: true, on: :submit
  validate :signature_matches_name, on: :submit

  before_submit :assign_confirmation_number

  scope :for_user, ->(user) { where(user_id: user.id) }

  def married? = marital_status == "married"
  def widowed? = marital_status == "widowed"
  def joint? = married? && filing_jointly == true
  def direct_deposit? = refund_method == "direct_deposit"

  def filer_full_name
    [ filer_name_first, filer_name_middle, filer_name_last ].compact_blank.join(" ")
  end

  def spouse_full_name
    [ spouse_name_first, spouse_name_middle, spouse_name_last ].compact_blank.join(" ")
  end

  def ssn_last_four(value = filer_ssn)
    value.to_s.last(4).presence
  end

  def year_end
    Date.new(tax_year, 12, 31)
  end

  def age_at_year_end(date_of_birth)
    return nil if date_of_birth.blank?

    # Everyone born in a year has had that year's birthday by December 31.
    tax_year - date_of_birth.to_date.year
  end

  def filer_age = age_at_year_end(filer_date_of_birth)
  def spouse_age = age_at_year_end(spouse_date_of_birth)

  def qualifying_dependents
    has_dependents ? dependents.select(&:qualifies?) : []
  end

  # Only unmarried people with a qualifying dependent can be head of
  # household or a qualifying surviving spouse, so only they are asked.
  def ask_home_costs?
    !married? && marital_status.present? && qualifying_dependents.any?
  end

  def ask_childcare?
    qualifying_dependents.any? { |dependent| dependent.age_at_year_end < 13 || dependent.disabled }
  end

  def filing_status
    FilingStatus.for(self)
  end

  def flow
    TaxReturnFlow.new(self)
  end

  def ready_to_calculate?
    flow.tasks.reject { |task| task.name == :refund }.all? { |task| task.completed?(self) }
  end

  # SSNs whose income records on file belong on this return.
  def ssns_on_return
    [ filer_ssn, (spouse_ssn if joint?) ].compact_blank
  end

  def total_colorado_withholding
    income_documents.included.sum(:colorado_withholding)
  end

  def tax_calculation
    TaxCalculation.new(calculation) if calculation.present?
  end

  # Runs the return through the tax engine and stores the result. Results are
  # reused while the facts are unchanged.
  def calculate!(client: TaxEngine.client)
    facts = TaxEngine::Facts.from_tax_return(self)
    digest = facts.digest
    return tax_calculation if calculation.present? && calculation_digest == digest

    result = client.calculate(facts.to_h)
    update_columns(calculation: result, calculation_digest: digest, calculated_at: Time.current)
    tax_calculation
  end

  private

  def filer_must_be_adult
    return if filer_date_of_birth.blank?

    errors.add(:filer_date_of_birth, :in_future) if filer_date_of_birth.to_date > year_end
    errors.add(:filer_date_of_birth, :too_young) if filer_age.present? && filer_age < 16
  end

  def spouse_ssn_differs_from_filer
    errors.add(:spouse_ssn, :same_as_filer) if spouse_ssn.present? && spouse_ssn == filer_ssn
  end

  def dependents_listed
    errors.add(:has_dependents, :add_a_dependent) if has_dependents && dependents.none?
  end

  def every_income_document_reviewed
    errors.add(:income_documents_reviewed, :review_each_form) if income_documents.unreviewed.any?
  end

  def signature_matches_name
    return if signature_name.blank?

    errors.add(:signature_name, :must_match_name) unless signature_name.squish.casecmp?(filer_full_name.squish)
  end

  def assign_confirmation_number
    self.confirmation_number ||= "CO-#{tax_year}-#{SecureRandom.alphanumeric(8).upcase}"
  end
end
