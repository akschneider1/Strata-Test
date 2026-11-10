# frozen_string_literal: true

module ReturnProcessing
  # System step: record the outcome of a return. In a real system this is
  # where the refund would be released or the balance due billed.
  class Finalize
    def self.call(kase)
      outcome = if kase.proposed_outcome == "not_accepted" then "not_accepted"
      elsif kase.return_adjustments.any? then "accepted_with_adjustments"
      else "accepted"
      end
      calculation = kase.current_calculation

      Strata::AuditLog.record do |log|
        kase.update!(outcome: outcome, decided_at: Time.current)
        log.add_line(
          action: "return.#{outcome}", subject: kase,
          data: { refund: calculation.refund, amount_owed: calculation.amount_owed, automatic: kase.review_flags.none? }
        )
      end

      Strata::EventManager.publish("TaxReturnFinalized", { case_id: kase.id })
    end
  end
end
