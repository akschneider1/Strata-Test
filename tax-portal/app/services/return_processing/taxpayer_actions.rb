# frozen_string_literal: true

module ReturnProcessing
  # What a taxpayer can do after filing.
  class TaxpayerActions
    def initialize(kase, taxpayer)
      @kase = kase
      @taxpayer = taxpayer
    end

    # Answer the examiner's open question; the return goes back for review,
    # to the examiner who asked.
    def respond_to_information_request(request, response)
      request.response = response
      return false unless request.valid?(:respond)

      Strata::AuditLog.record(actor: @taxpayer) do |log|
        request.update!(responded_at: Time.current)
        log.add_line(action: "taxpayer.information_provided", subject: @kase, data: { information_request_id: request.id })
      end
      Strata::EventManager.publish("TaxReturnInformationProvided", { case_id: @kase.id })
      @kase.reload.open_review_task&.assign(request.requested_by_id)
      true
    end
  end
end
