# frozen_string_literal: true

# An income form on a tax return. It either comes from a record on file with
# the Department (source "on_file"), which the taxpayer confirms, corrects or
# disputes, or is entered by the taxpayer (source "taxpayer").
class IncomeDocument < ApplicationRecord
  KINDS = WageRecord::KINDS
  OWNERS = %w[filer spouse].freeze
  SOURCES = %w[on_file taxpayer].freeze
  # unreviewed: prefilled, not yet looked at by the taxpayer
  # confirmed:  taxpayer says the record on file is right
  # corrected:  taxpayer changed an amount from the record on file
  # disputed:   taxpayer says the record is not theirs (left off the return)
  # entered:    typed in by the taxpayer
  REVIEW_STATUSES = %w[unreviewed confirmed corrected disputed entered].freeze

  belongs_to :tax_return
  belongs_to :wage_record, optional: true

  validates :kind, inclusion: { in: KINDS, message: :choose_one }
  validates :owner, inclusion: { in: OWNERS, message: :choose_one }
  validates :source, inclusion: { in: SOURCES }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :payer_name, presence: true
  validates :amount, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: TaxReturn::MAX_AMOUNT }
  validates :colorado_withholding, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: TaxReturn::MAX_AMOUNT }
  validate :withholding_not_more_than_amount

  scope :unreviewed, -> { where(review_status: "unreviewed") }
  scope :included, -> { where.not(review_status: %w[unreviewed disputed]) }
  scope :of_kind, ->(kind) { where(kind: kind) }
  scope :in_display_order, -> { order(:owner, :kind, :created_at) }

  def on_file? = source == "on_file"
  def included? = !review_status.in?(%w[unreviewed disputed])

  def differs_from_record?
    wage_record.present? && (amount != wage_record.amount || colorado_withholding != wage_record.colorado_withholding)
  end

  # Applies the taxpayer's decision about a prefilled form.
  def confirm!
    update!(amount: wage_record.amount, colorado_withholding: wage_record.colorado_withholding, review_status: "confirmed")
  end

  def dispute!
    update!(review_status: "disputed")
  end

  def correct!(attributes)
    assign_attributes(attributes)
    self.review_status = differs_from_record? ? "corrected" : "confirmed"
    save
  end

  private

  def withholding_not_more_than_amount
    return if amount.blank? || colorado_withholding.blank?

    errors.add(:colorado_withholding, :more_than_amount) if colorado_withholding > amount
  end
end
