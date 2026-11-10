# frozen_string_literal: true

# Income reported to the Department of Revenue by an employer or payer
# (W-2 and 1099 information returns). Used to prefill the taxpayer's return
# and to check what they report. Seeded in this prototype.
class WageRecord < ApplicationRecord
  KINDS = %w[w2 form_1099g form_1099r ssa_1099].freeze

  encrypts :ssn, deterministic: true

  validates :ssn, format: { with: TaxReturn::SSN_FORMAT }
  validates :kind, inclusion: { in: KINDS }
  validates :payer_name, :tax_year, presence: true
  validates :amount, :colorado_withholding, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Records for the people on a return. In the demo, only records in the
  # same copy of the demo as the person filing.
  scope :for_return, ->(tax_return) {
    where(ssn: tax_return.ssns_on_return, tax_year: tax_return.tax_year, demo_space_id: tax_return.user.demo_space_id)
  }
end
