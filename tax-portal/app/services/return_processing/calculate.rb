# frozen_string_literal: true

module ReturnProcessing
  # System step: run the filed return through the tax engine and keep the
  # facts and result on the case, so later steps and examiners see exactly
  # what was calculated and by which version of the rules.
  class Calculate
    def self.call(kase)
      tax_return = kase.tax_return
      facts = TaxEngine::Facts.from_tax_return(tax_return)
      calculation = tax_return.calculate!

      Strata::AuditLog.record do |log|
        kase.update!(facts: kase.facts.merge("filed_facts" => facts.to_h, "filed_calculation" => calculation.data))
        log.add_line(
          action: "return.calculated", subject: kase,
          data: { engine: calculation.engine, engine_version: calculation.engine_version, refund: calculation.refund, amount_owed: calculation.amount_owed }
        )
      end

      Strata::EventManager.publish("TaxReturnCalculated", { case_id: kase.id })
    end
  end
end
