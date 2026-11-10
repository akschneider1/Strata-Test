# frozen_string_literal: true

# One reason the automatic checks sent a return to an examiner.
class ReviewFlag < ApplicationRecord
  CODES = %w[
    income_lower_than_record
    withholding_higher_than_record
    income_record_disputed
    withholding_without_record
    dependent_claimed_elsewhere
    large_refund_for_income
  ].freeze

  belongs_to :tax_return_case

  validates :code, inclusion: { in: CODES }

  scope :unresolved, -> { where(resolved_at: nil) }

  def resolved? = resolved_at.present?
end
