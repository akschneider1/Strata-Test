# frozen_string_literal: true

# Brings income forms the Department already has (reported by employers and
# payers) onto a taxpayer's return, so they confirm instead of retyping.
class RecordsOnFile
  def self.prefill(tax_return)
    return [] if tax_return.submitted? || tax_return.ssns_on_return.empty?

    linked = tax_return.income_documents.where.not(wage_record_id: nil).pluck(:wage_record_id)
    WageRecord.for_return(tax_return).where.not(id: linked).map do |record|
      tax_return.income_documents.create!(
        wage_record: record, kind: record.kind, payer_name: record.payer_name,
        owner: record.ssn == tax_return.filer_ssn ? "filer" : "spouse",
        amount: record.amount, colorado_withholding: record.colorado_withholding,
        source: "on_file", review_status: "unreviewed"
      )
    end
  end
end
