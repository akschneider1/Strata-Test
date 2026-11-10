# frozen_string_literal: true

# How the service is doing, worked out from what processing already records:
# cases, flags, adjustments, questions to taxpayers and decision times.
#
# Read-only. Dollar figures are differences between results the tax engine
# produced; nothing here calculates tax.
class ServiceMeasures
  def initialize(cases: TaxReturnCase.submitted)
    @cases = cases.includes(:tax_return, :review_flags, :return_adjustments, :information_requests).to_a
  end

  def filed = @cases.size
  def decided = decided_cases.size
  def in_review = @cases.count { |kase| kase.step == "review_return" }
  def waiting_on_taxpayer = @cases.count { |kase| kase.step == "provide_information" }

  # Decided with no flag, so no person touched the return.
  def accepted_automatically = automatic_cases.size

  # Sent to an examiner by the automatic checks, whatever happened next.
  def flagged = flagged_cases.size

  def accepted_after_review = reviewed_cases.count { |kase| kase.outcome == "accepted" }
  def accepted_with_adjustments = reviewed_cases.count { |kase| kase.outcome == "accepted_with_adjustments" }

  # Share of filed returns, as a whole percentage, or nil when none are filed.
  def share(count)
    (count * 100.0 / filed).round if filed.positive?
  end

  # [[flag code, number of returns it was raised on]], most common first.
  def flags_by_code
    flagged_cases.flat_map { |kase| kase.review_flags.map(&:code).uniq }.tally.sort_by { |code, count| [ -count, code ] }
  end

  # Median time from filing to a decision, in seconds.
  def median_time_to_decision_automatic = median(automatic_cases.filter_map { |kase| time_to_decision(kase) })
  def median_time_to_decision_reviewed = median(reviewed_cases.filter_map { |kase| time_to_decision(kase) })

  def returns_adjusted = adjusted_cases.size

  # Total change to what taxpayers receive (refund less amount owed) from
  # examiner adjustments. Negative means taxpayers received less than filed.
  def net_change_from_adjustments
    adjusted_cases.sum do |kase|
      net(kase.adjusted_calculation) - net(kase.filed_calculation)
    end
  end

  def questions_asked = requests.size
  def questions_open = open_requests.size
  def oldest_open_question_asked_at = open_requests.map(&:created_at).min

  # Median time a taxpayer took to answer, in seconds.
  def median_time_to_answer
    median(requests.select(&:answered?).map { |request| request.responded_at - request.created_at })
  end

  private

  def decided_cases = @decided_cases ||= @cases.select { |kase| kase.outcome.present? }
  def flagged_cases = @flagged_cases ||= @cases.select { |kase| kase.review_flags.any? }
  def automatic_cases = decided_cases - flagged_cases
  def reviewed_cases = decided_cases & flagged_cases
  def requests = @requests ||= @cases.flat_map(&:information_requests)
  def open_requests = requests.reject(&:answered?)

  def adjusted_cases
    @adjusted_cases ||= @cases.select { |kase| kase.return_adjustments.any? && kase.adjusted_calculation && kase.filed_calculation }
  end

  def time_to_decision(kase)
    submitted_at = kase.tax_return.submitted_at
    kase.decided_at - submitted_at if kase.decided_at && submitted_at
  end

  def net(calculation) = calculation.refund - calculation.amount_owed

  def median(values)
    return nil if values.empty?

    sorted = values.sort
    middle = sorted.size / 2
    sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
  end
end
