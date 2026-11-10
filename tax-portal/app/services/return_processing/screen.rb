# frozen_string_literal: true

module ReturnProcessing
  # System step: automatic checks on a filed return. Each rule that fires
  # creates a ReviewFlag explaining why; any flag sends the return to an
  # examiner, otherwise it is accepted automatically.
  #
  # The rules are deliberately simple and readable. Thresholds here are
  # illustrative, not Department policy.
  class Screen
    # A refund above this share of total income gets a second look.
    LARGE_REFUND_SHARE = 0.30
    LARGE_REFUND_MINIMUM = 2_500

    def self.call(kase)
      new(kase).call
    end

    def initialize(kase)
      @kase = kase
      @tax_return = kase.tax_return
      @flags = []
    end

    def call
      check_income_against_records
      check_withholding_without_record
      check_dependents_claimed_elsewhere
      check_large_refund

      Strata::AuditLog.record do |log|
        @flags.each { |flag| @kase.review_flags.create!(flag) }
        log.add_line(action: "return.screened", subject: @kase, data: { flags: @flags.map { |flag| flag[:code] } })
      end

      Strata::EventManager.publish(@flags.any? ? "TaxReturnFlagged" : "TaxReturnCleared", { case_id: @kase.id })
    end

    private

    def flag(code, details = {})
      @flags << { code: code, details: details }
    end

    def check_income_against_records
      @tax_return.income_documents.includes(:wage_record).select(&:on_file?).each do |document|
        record = document.wage_record
        base = { income_document_id: document.id, kind: document.kind, payer_name: document.payer_name }

        if document.review_status == "disputed"
          flag("income_record_disputed", base.merge(on_file_amount: record.amount))
          next
        end
        if document.amount < record.amount
          flag("income_lower_than_record", base.merge(reported: document.amount, on_file: record.amount))
        end
        if document.colorado_withholding > record.colorado_withholding
          flag("withholding_higher_than_record", base.merge(reported: document.colorado_withholding, on_file: record.colorado_withholding))
        end
      end
    end

    def check_withholding_without_record
      @tax_return.income_documents.included.reject(&:on_file?).select { |document| document.colorado_withholding.positive? }.each do |document|
        flag("withholding_without_record", { income_document_id: document.id, kind: document.kind, payer_name: document.payer_name, reported: document.colorado_withholding })
      end
    end

    def check_dependents_claimed_elsewhere
      @tax_return.dependents.each do |dependent|
        other = Dependent.joins(:tax_return)
          .where(ssn: dependent.ssn, tax_returns: { tax_year: @tax_return.tax_year, status: TaxReturn.statuses[:submitted] })
          .where.not(tax_return_id: @tax_return.id)
          .first
        next unless other

        flag("dependent_claimed_elsewhere", { dependent_id: dependent.id, dependent_name: dependent.full_name, other_confirmation_number: other.tax_return.confirmation_number })
      end
    end

    def check_large_refund
      calculation = @kase.filed_calculation
      income = calculation.amount("total_income")
      refund = calculation.refund
      return unless refund >= LARGE_REFUND_MINIMUM && refund > income * LARGE_REFUND_SHARE

      flag("large_refund_for_income", { refund: refund, total_income: income })
    end
  end
end
