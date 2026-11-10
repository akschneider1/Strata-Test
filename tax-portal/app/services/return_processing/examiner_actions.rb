# frozen_string_literal: true

module ReturnProcessing
  # What an examiner can do to a return under review. Every action is
  # written to the audit log with the examiner as the actor.
  class ExaminerActions
    class NotUnderReview < StandardError; end

    def initialize(kase, examiner)
      @kase = kase
      @examiner = examiner
    end

    # Accept the return as it now stands (as filed, or with adjustments).
    def approve
      ensure_under_review!
      Strata::AuditLog.record(actor: @examiner) do |log|
        @kase.unresolved_flags.update_all(resolved_at: Time.current, resolved_by_id: @examiner.id)
        complete_review_task
        log.add_line(action: "review.approved", subject: @kase, data: { adjustments: @kase.return_adjustments.count })
      end
      Strata::EventManager.publish("TaxReturnApproved", { case_id: @kase.id })
    end

    # Ask the taxpayer a question. The return waits for their answer.
    def request_information(question)
      ensure_under_review!
      request = @kase.information_requests.new(question: question, requested_by: @examiner)
      return request unless request.valid?

      Strata::AuditLog.record(actor: @examiner) do |log|
        request.save!
        complete_review_task
        log.add_line(action: "review.information_requested", subject: @kase, data: { information_request_id: request.id })
      end
      Strata::EventManager.publish("TaxReturnInformationRequested", { case_id: @kase.id })
      request
    end

    # Change one filed amount and recalculate the return.
    def adjust(field:, amount:, reason:, client: TaxEngine.client)
      ensure_under_review!
      adjustment = @kase.return_adjustments.new(
        field: field, adjusted_amount: amount, reason: reason, adjusted_by: @examiner,
        filed_amount: TaxEngine::Facts::ADJUSTABLE.key?(field) ? current_amount(field) : 0
      )
      return adjustment unless adjustment.valid?

      Strata::AuditLog.record(actor: @examiner) do |log|
        adjustment.save!
        before = @kase.current_calculation
        after = TaxCalculation.new(client.calculate(@kase.adjusted_facts.to_h))
        @kase.update!(facts: @kase.facts.merge("adjusted_calculation" => after.data))
        log.add_line(
          action: "review.adjusted", subject: @kase,
          data: {
            field: field, from: adjustment.filed_amount, to: adjustment.adjusted_amount,
            refund_before: before.refund, refund_after: after.refund,
            amount_owed_before: before.amount_owed, amount_owed_after: after.amount_owed
          }
        )
      end
      adjustment
    end

    def add_note(body)
      note = @kase.case_notes.new(body: body, author: @examiner)
      return note unless note.valid?

      Strata::AuditLog.record(actor: @examiner) do |log|
        note.save!
        log.add_line(action: "review.note_added", subject: @kase, data: { case_note_id: note.id })
      end
      note
    end

    private

    def ensure_under_review!
      raise NotUnderReview, "Case #{@kase.id} is at step #{@kase.step}" unless @kase.step == "review_return"
    end

    # The amount before this adjustment: an earlier adjustment if there is
    # one, otherwise what the taxpayer filed.
    def current_amount(field)
      @kase.adjusted_facts.value(field)
    end

    def complete_review_task
      task = @kase.open_review_task
      return unless task

      task.assign(@examiner.id) if task.assignee_id.blank?
      task.completed!
    end
  end
end
