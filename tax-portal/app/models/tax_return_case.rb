# frozen_string_literal: true

# Tracks one tax return through processing: calculation, automatic checks,
# examiner review when needed, and the final outcome.
class TaxReturnCase < Strata::Case
  include Strata::Auditable

  OUTCOMES = %w[accepted accepted_with_adjustments not_accepted].freeze

  belongs_to :tax_return, foreign_key: :application_form_id, inverse_of: :tax_return_case
  has_many :review_flags, dependent: :destroy
  has_many :information_requests, dependent: :destroy
  has_many :return_adjustments, dependent: :destroy
  has_many :case_notes, dependent: :destroy

  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true

  scope :newest_first, -> { order(created_at: :desc) }
  scope :submitted, -> { where.not(business_process_current_step: "file_return") }

  # Strata looks the form class up by name; ours is TaxReturn, not
  # TaxReturnApplicationForm.
  def self.application_form_class = "TaxReturn"

  def step = business_process_current_step

  def filed_calculation
    TaxCalculation.new(facts["filed_calculation"]) if facts["filed_calculation"].present?
  end

  def adjusted_calculation
    TaxCalculation.new(facts["adjusted_calculation"]) if facts["adjusted_calculation"].present?
  end

  # The calculation that currently stands: adjusted if an examiner changed
  # anything, otherwise as filed.
  def current_calculation = adjusted_calculation || filed_calculation

  def filed_facts
    TaxEngine::Facts.new(facts.fetch("filed_facts"))
  end

  # Latest adjusted amount per field.
  def adjustments_by_field
    return_adjustments.order(:created_at).each_with_object({}) { |adjustment, map| map[adjustment.field] = adjustment.adjusted_amount }
  end

  def adjusted_facts
    filed_facts.with_adjustments(adjustments_by_field)
  end

  # Filed but not yet through calculation and the automatic checks.
  def processing_stalled?
    step.in?(%w[file_return calculate_return screen_return finalize_return]) && tax_return.submitted?
  end

  def open_information_request
    information_requests.where(responded_at: nil).order(:created_at).last
  end

  # The examiner task waiting to be done on this return, if any: a review,
  # or a second examiner's confirmation.
  def open_task
    tasks.reject(&:completed?).max_by(&:created_at)
  end

  def open_review_task
    tasks.select { |task| task.is_a?(ReviewTask) && !task.completed? }.max_by(&:created_at)
  end

  # What the first examiner proposed, while a second examiner decides.
  def proposal = facts["proposal"] || {}
  def proposed_outcome = proposal["outcome"]
  def proposed_by_id = proposal["proposed_by_id"]
  def proposed_by = (User.find_by(id: proposed_by_id) if proposed_by_id)
  # Why the return was not accepted. Shown to the taxpayer.
  def not_accepted_reason = proposal["reason"]
  def accepted? = outcome.in?(%w[accepted accepted_with_adjustments])

  def unresolved_flags = review_flags.where(resolved_at: nil)

  # Taxpayer-facing stage of the return.
  def stage
    case step
    when "file_return" then :not_submitted
    when "calculate_return", "screen_return" then :received
    when "review_return", "second_review" then :in_review
    when "provide_information" then :needs_information
    else
      if outcome == "not_accepted" then :not_accepted
      elsif outcome.present? then :accepted
      else :received
      end
    end
  end
end
