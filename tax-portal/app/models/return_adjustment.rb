# frozen_string_literal: true

# An examiner's change to one amount on a filed return, with the reason.
class ReturnAdjustment < ApplicationRecord
  belongs_to :tax_return_case
  belongs_to :adjusted_by, class_name: "User"

  validates :field, inclusion: { in: TaxEngine::Facts::ADJUSTABLE.keys, message: :choose_one }
  validates :adjusted_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: TaxReturn::MAX_AMOUNT }
  validates :reason, presence: true, length: { maximum: 1000 }
  validate :amount_changes

  private

  def amount_changes
    errors.add(:adjusted_amount, :unchanged) if adjusted_amount.present? && adjusted_amount == filed_amount
  end
end
