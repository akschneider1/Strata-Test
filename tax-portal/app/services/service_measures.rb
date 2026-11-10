# frozen_string_literal: true

# How the service is doing, worked out from what processing already records:
# cases, flags, adjustments, questions to taxpayers and decision times.
#
# Read-only. Everything is counted by the database, so the page costs the
# same whether there are a hundred returns or millions. Dollar figures are
# differences between results the tax engine produced; nothing here
# calculates tax.
class ServiceMeasures
  def initialize(cases: TaxReturnCase.submitted)
    # Strata cases load their tasks by default. In totals that would join the
    # tasks in and count a case once per task.
    @cases = cases.unscope(:includes)
  end

  def filed = @filed ||= @cases.count
  def decided = decided_cases.count
  def waiting_to_be_processed = by_step[ReturnProcessing::PENDING_STEP].to_i
  def in_review = by_step["review_return"].to_i
  def waiting_on_taxpayer = by_step["provide_information"].to_i

  # Decided with no flag, so no person touched the return.
  def accepted_automatically = decided_cases.where.not(id: flagged_ids).count

  # Sent to an examiner by the automatic checks, whatever happened next.
  def flagged = flagged_cases.count

  def accepted_after_review = flagged_cases.where(outcome: "accepted").count
  def accepted_with_adjustments = flagged_cases.where(outcome: "accepted_with_adjustments").count

  # Share of filed returns, as a whole percentage, or nil when none are filed.
  def share(count)
    (count * 100.0 / filed).round if filed.positive?
  end

  # [[flag code, number of returns it was raised on]], most common first.
  def flags_by_code
    ReviewFlag.where(tax_return_case_id: @cases.select(:id)).group(:code).distinct.count(:tax_return_case_id)
      .sort_by { |code, count| [ -count, code ] }
  end

  # Median time from filing to a decision, in seconds.
  def median_time_to_decision_automatic = median_time_to_decision(decided_cases.where.not(id: flagged_ids))
  def median_time_to_decision_reviewed = median_time_to_decision(decided_cases.where(id: flagged_ids))

  def returns_adjusted = adjusted_cases.count

  # Total change to what taxpayers receive (refund less amount owed) from
  # examiner adjustments. Negative means taxpayers received less than filed.
  def net_change_from_adjustments
    net = ->(calculation) { "((facts->'#{calculation}'->>'refund')::numeric - (facts->'#{calculation}'->>'amount_owed')::numeric)" }
    adjusted_cases.sum(Arel.sql("#{net.call('adjusted_calculation')} - #{net.call('filed_calculation')}")).to_i
  end

  def questions_asked = requests.count
  def questions_open = requests.where(responded_at: nil).count
  def oldest_open_question_asked_at = requests.where(responded_at: nil).minimum(:created_at)

  # Median time a taxpayer took to answer, in seconds.
  def median_time_to_answer
    median(requests.where.not(responded_at: nil), "information_requests.responded_at - information_requests.created_at")
  end

  private

  def by_step = @by_step ||= @cases.group(:business_process_current_step).count
  def decided_cases = @cases.where.not(outcome: nil)
  def flagged_ids = ReviewFlag.select(:tax_return_case_id)
  def flagged_cases = @cases.where(id: flagged_ids)
  def requests = InformationRequest.where(tax_return_case_id: @cases.select(:id))

  def adjusted_cases
    @cases.where(id: ReturnAdjustment.select(:tax_return_case_id)).where("facts ? 'adjusted_calculation' AND facts ? 'filed_calculation'")
  end

  def median_time_to_decision(cases)
    median(cases.joins(:tax_return).where.not(tax_returns: { submitted_at: nil }), "tax_return_cases.decided_at - tax_returns.submitted_at")
  end

  # Median of an interval expression over a relation, in seconds.
  def median(relation, interval)
    relation.pick(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (#{interval})))"))&.to_f
  end
end
