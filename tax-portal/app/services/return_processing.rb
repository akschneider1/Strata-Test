# frozen_string_literal: true

# Backend processing of filed returns. See TaxReturnBusinessProcess for the
# steps and ProcessReturnJob for how they are started.
module ReturnProcessing
  # A filed return waits at this step until it has been calculated.
  PENDING_STEP = "calculate_return"
  # Calculation in the background can wait longer for the engine than a
  # taxpayer looking at a page can.
  BACKGROUND_TIMEOUT = 60

  def self.pending
    TaxReturnCase.where(business_process_current_step: PENDING_STEP)
  end

  # Processes returns that were filed but not yet calculated, oldest first.
  # Safe to run at any time and from several places at once. Returns how many
  # cases moved on.
  def self.process_pending(limit: 500)
    pending.order(:created_at).limit(limit).pluck(:id).count do |case_id|
      ProcessReturnJob.perform_now(case_id)
      TaxReturnCase.where(id: case_id).where.not(business_process_current_step: PENDING_STEP).exists?
    end
  end
end
