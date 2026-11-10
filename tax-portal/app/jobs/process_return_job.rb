# frozen_string_literal: true

# Runs a filed return through calculation, the automatic checks and, when
# nothing is flagged, acceptance. Filing only records the return and queues
# this job, so a slow or unavailable tax engine never holds up the taxpayer
# or loses a filing.
#
# The case itself is the durable record of what is left to do: a case still
# at the "calculate_return" step has not been processed. If this job fails or
# is lost, ReturnProcessing.process_pending (run on a schedule) picks the
# case up again.
class ProcessReturnJob < ApplicationJob
  queue_as :default
  # Filing happens inside a database transaction. Start only once it has
  # been saved, or the job would not see the filed return.
  self.enqueue_after_transaction_commit = true

  def perform(case_id)
    kase = TaxReturnCase.find_by(id: case_id)
    return unless kase

    kase.with_lock do
      # Another worker may have processed it while we waited for the lock.
      next unless kase.step == ReturnProcessing::PENDING_STEP

      ReturnProcessing::Calculate.call(kase)
    end
  rescue TaxEngine::Error => error
    # Leave the case where it is; the scheduled sweep will try again.
    Rails.logger.warn("Return processing postponed for case #{case_id}: #{error.class.name}")
  end
end
