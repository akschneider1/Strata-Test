# frozen_string_literal: true

class Dependent < ApplicationRecord
  RELATIONSHIPS = %w[child stepchild foster_child grandchild sibling parent other_relative].freeze
  CHILD_RELATIONSHIPS = %w[child stepchild foster_child grandchild sibling].freeze
  CHILD_AGE_LIMIT = 19
  STUDENT_AGE_LIMIT = 24

  include Strata::Attributes

  belongs_to :tax_return

  strata_attribute :date_of_birth, :memorable_date

  encrypts :ssn, deterministic: true
  normalizes :ssn, with: ->(value) { value.to_s.gsub(/\D/, "").presence }

  validates :name_first, :name_last, :date_of_birth, presence: true
  validates :relationship, inclusion: { in: RELATIONSHIPS, message: :choose_one }
  validates :ssn, presence: true, format: { with: TaxReturn::SSN_FORMAT, message: :invalid_ssn, allow_blank: true }
  validates :ssn, uniqueness: { scope: :tax_return_id, message: :already_listed }
  validate :born_by_year_end
  validate :ssn_not_a_filers
  with_options on: :support do
    validates :income_under_limit, inclusion: { in: [ true, false ], message: :choose_one }
    validates :supported_by_filer, inclusion: { in: [ true, false ], message: :choose_one }
  end

  def full_name = "#{name_first} #{name_last}"

  def age_at_year_end
    tax_return.age_at_year_end(date_of_birth)
  end

  # Whether this person can be claimed, following the federal tests (IRS
  # Publication 501). Still simplified: it does not ask whether a child paid
  # for most of their own support, or whether someone else can claim them.
  def qualifies?
    qualifying_child? || qualifying_relative?
  end

  # A son, daughter, grandchild, brother or sister (and step or foster
  # equivalents) who lived with the filer and is under 19, under 24 and a
  # full-time student, or permanently disabled.
  def qualifying_child?
    CHILD_RELATIONSHIPS.include?(relationship) && lived_with_filer_over_half_year == true && child_age_test?
  end

  # Anyone else: they must have little income of their own and get most of
  # their support from the filer. A parent need not live with the filer.
  def qualifying_relative?
    !qualifying_child? && residency_for_relative? && income_under_limit == true && supported_by_filer == true
  end

  # The income and support questions only matter for someone who could be a
  # qualifying relative.
  def needs_support_questions?
    !qualifying_child? && residency_for_relative?
  end

  def support_questions_answered?
    !needs_support_questions? || (!income_under_limit.nil? && !supported_by_filer.nil?)
  end

  # Why this person does or doesn't count, for the taxpayer.
  def qualification
    if qualifying_child? then :qualifying_child
    elsif !residency_for_relative? then :did_not_live_with_you
    elsif !support_questions_answered? then :needs_answers
    elsif income_under_limit == false then :income_too_high
    elsif supported_by_filer == false then :not_supported_by_you
    else :qualifying_relative
    end
  end

  def ssn_last_four = ssn.to_s.last(4)

  private

  def child_age_test?
    age = age_at_year_end
    return false if age.nil?

    disabled || age < CHILD_AGE_LIMIT || (full_time_student && age < STUDENT_AGE_LIMIT)
  end

  def residency_for_relative?
    lived_with_filer_over_half_year == true || relationship == "parent"
  end

  # A dependent can't be one of the people filing the return.
  def ssn_not_a_filers
    return if ssn.blank? || tax_return.nil?

    errors.add(:ssn, :same_as_filer) if ssn == tax_return.filer_ssn
    errors.add(:ssn, :same_as_spouse) if ssn == tax_return.spouse_ssn
  end

  def born_by_year_end
    errors.add(:date_of_birth, :in_future) if date_of_birth.present? && date_of_birth.to_date > tax_return.year_end
  end
end
