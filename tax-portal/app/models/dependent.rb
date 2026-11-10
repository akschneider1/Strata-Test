# frozen_string_literal: true

class Dependent < ApplicationRecord
  RELATIONSHIPS = %w[child stepchild foster_child grandchild sibling parent other_relative].freeze

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

  def full_name = "#{name_first} #{name_last}"

  def age_at_year_end
    tax_return.age_at_year_end(date_of_birth)
  end

  # Simplified from the federal qualifying child / qualifying relative tests:
  # the person must have lived with the filer for more than half the year.
  def qualifies?
    lived_with_filer_over_half_year
  end

  def ssn_last_four = ssn.to_s.last(4)

  private

  def born_by_year_end
    errors.add(:date_of_birth, :in_future) if date_of_birth.present? && date_of_birth.to_date > tax_return.year_end
  end
end
