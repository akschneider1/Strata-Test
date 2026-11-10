# frozen_string_literal: true

module ReturnProcessing
  # What an examiner can do to a return under review. Every action is
  # written to the audit log with the examiner as the actor.
  #
  # Controls:
  # - Only the examiner the return is assigned to can act on it.
  # - A change of SECOND_APPROVAL_THRESHOLD dollars or more to what the
  #   taxpayer receives, or a decision not to accept the return, has to be
  #   confirmed by a different examiner.
  class ExaminerActions
    class NotUnderReview < StandardError; end
    class NotAssigned < StandardError; end
    class SameExaminer < StandardError; end

    # Illustrative, not Department policy.
    SECOND_APPROVAL_THRESHOLD = 500

    def initialize(kase, examiner)
      @kase = kase
      @examiner = examiner
    end

    # Take the open task on this return, whoever has it now.
    def assign_to_me
      task = @kase.open_task
      return unless task && task.assignee_id != @examiner.id

      Strata::AuditLog.record(actor: @examiner) do |log|
        previous = task.assignee_id
        task.assign(@examiner.id)
        log.add_line(action: "review.assigned", subject: @kase, data: { taken_over: previous.present? })
      end
    end

    # Accept the return as it now stands (as filed, or with adjustments).
    # Large adjustments go to a second examiner first.
    def approve
      ensure_under_review!
      return propose("accepted_with_adjustments") if needs_second_approval?

      Strata::AuditLog.record(actor: @examiner) do |log|
        resolve_flags
        complete_open_task
        log.add_line(action: "review.approved", subject: @kase, data: { adjustments: @kase.return_adjustments.count })
      end
      Strata::EventManager.publish("TaxReturnApproved", { case_id: @kase.id })
    end

    # Decide not to accept the return. Always needs a second examiner.
    # Returns nil when no reason is given.
    def reject(reason)
      ensure_under_review!
      return nil if reason.blank?

      propose("not_accepted", reason.to_s.strip)
    end

    # A second examiner agrees with what was proposed.
    def confirm
      ensure_second_review!
      Strata::AuditLog.record(actor: @examiner) do |log|
        resolve_flags
        complete_open_task
        log.add_line(action: "review.confirmed", subject: @kase, data: { proposed_outcome: @kase.proposed_outcome })
      end
      Strata::EventManager.publish("TaxReturnApproved", { case_id: @kase.id })
    end

    # A second examiner disagrees. The return goes back to the examiner who
    # proposed the outcome, with a note saying why. Returns nil when no note
    # is given.
    def send_back(note)
      ensure_second_review!
      return nil if note.blank?

      proposer_id = @kase.proposed_by_id
      Strata::AuditLog.record(actor: @examiner) do |log|
        @kase.case_notes.create!(body: note.to_s.strip, author: @examiner)
        complete_open_task
        @kase.update!(facts: @kase.facts.except("proposal"))
        log.add_line(action: "review.sent_back", subject: @kase, data: {})
      end
      Strata::EventManager.publish("TaxReturnSentBack", { case_id: @kase.id })
      @kase.reload.open_task&.assign(proposer_id)
      true
    end

    # Ask the taxpayer a question. The return waits for their answer.
    def request_information(question)
      ensure_under_review!
      request = @kase.information_requests.new(question: question, requested_by: @examiner)
      return request unless request.valid?

      Strata::AuditLog.record(actor: @examiner) do |log|
        request.save!
        complete_open_task
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

    # Whether accepting the return now would need a second examiner.
    def needs_second_approval?
      return false unless @kase.return_adjustments.any? && @kase.adjusted_calculation

      change = net(@kase.adjusted_calculation) - net(@kase.filed_calculation)
      change.abs >= SECOND_APPROVAL_THRESHOLD
    end

    private

    def ensure_under_review!
      raise NotUnderReview, "Case #{@kase.id} is at step #{@kase.step}" unless @kase.step == "review_return"

      ensure_assigned!
    end

    def ensure_second_review!
      raise NotUnderReview, "Case #{@kase.id} is at step #{@kase.step}" unless @kase.step == "second_review"
      raise SameExaminer, "The examiner who proposed an outcome can't confirm it" if @kase.proposed_by_id == @examiner.id

      # Confirming is a task of its own: picking it up is part of doing it.
      task = @kase.open_task
      task.assign(@examiner.id) if task && task.assignee_id.blank?
      ensure_assigned!
    end

    def ensure_assigned!
      task = @kase.open_task
      raise NotAssigned, "Case #{@kase.id} is not assigned to this examiner" unless task && task.assignee_id == @examiner.id
    end

    # Record what this examiner proposes and hand the return to a second one.
    def propose(outcome, reason = nil)
      Strata::AuditLog.record(actor: @examiner) do |log|
        complete_open_task
        proposal = { "outcome" => outcome, "proposed_by_id" => @examiner.id, "reason" => reason }.compact
        @kase.update!(facts: @kase.facts.merge("proposal" => proposal))
        log.add_line(action: "review.second_approval_requested", subject: @kase, data: { proposed_outcome: outcome })
      end
      Strata::EventManager.publish("TaxReturnSecondReviewRequested", { case_id: @kase.id })
      :second_review
    end

    def resolve_flags
      @kase.unresolved_flags.update_all(resolved_at: Time.current, resolved_by_id: @examiner.id)
    end

    # The amount before this adjustment: an earlier adjustment if there is
    # one, otherwise what the taxpayer filed.
    def current_amount(field)
      @kase.adjusted_facts.value(field)
    end

    def complete_open_task
      @kase.open_task&.completed!
    end

    def net(calculation) = calculation.refund - calculation.amount_owed
  end
end
