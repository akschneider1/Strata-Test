# frozen_string_literal: true

require 'rails_helper'

# The business process end to end, with the fake tax engine:
# (income - 15,750) x 4.4% tax, minus withholding.
RSpec.describe ReturnProcessing do
  let(:examiner) { create(:examiner) }

  def actions(kase, user = examiner)
    ReturnProcessing::ExaminerActions.new(kase, user)
  end

  describe "a return with nothing to review" do
    let(:kase) { create(:tax_return, :submitted).tax_return_case }

    it "is calculated, cleared and accepted without anyone touching it" do
      expect(kase).to have_attributes(step: "end", outcome: "accepted", status: "closed", stage: :accepted)
      expect(kase.review_flags).to be_empty
      expect(kase.tasks).to be_empty
      expect(kase.filed_calculation.refund).to eq(231)
      expect(kase.audit_lines.order(:created_at).pluck(:action)).to eq(%w[return.calculated return.screened return.accepted])
    end

    it "records which rules engine produced the numbers" do
      expect(kase.audit_lines.find_by(action: "return.calculated").data).to include("engine" => "fake", "engine_version" => "0", "refund" => 231)
    end

    it "cannot be acted on by an examiner" do
      expect { actions(kase).approve }.to raise_error(ReturnProcessing::ExaminerActions::NotUnderReview)
    end
  end

  describe "automatic checks" do
    def flags_for(tax_return)
      tax_return.assign_attributes(declaration_accepted: true, signature_name: tax_return.filer_full_name)
      tax_return.submit_application
      tax_return.tax_return_case.review_flags.pluck(:code)
    end

    let(:tax_return) { create(:tax_return, :complete) }

    it "flags withholding higher than the payer reported" do
      tax_return.income_documents.first.correct!(colorado_withholding: 2_650)

      expect(flags_for(tax_return)).to eq(%w[withholding_higher_than_record])
    end

    it "flags income lower than the payer reported" do
      tax_return.income_documents.first.correct!(amount: 40_000)

      expect(flags_for(tax_return)).to eq(%w[income_lower_than_record])
    end

    it "does not flag a correction in the Department's favor" do
      tax_return.income_documents.first.correct!(amount: 50_000, colorado_withholding: 1_000)

      expect(flags_for(tax_return)).to be_empty
    end

    it "flags a record on file the taxpayer says is not theirs" do
      tax_return.income_documents.first.dispute!

      expect(flags_for(tax_return)).to eq(%w[income_record_disputed])
    end

    it "flags withholding on a form the Department has no record of" do
      tax_return.income_documents.create!(kind: "w2", payer_name: "Side Job LLC", amount: 5_000, colorado_withholding: 400, source: "taxpayer", review_status: "entered")

      expect(flags_for(tax_return)).to eq(%w[withholding_without_record])
    end

    it "flags a dependent already claimed on another filed return" do
      other = create(:tax_return, :complete, has_dependents: true, paid_over_half_home_costs: false, paid_childcare: false)
      create(:dependent, tax_return: other, ssn: "000770001")
      flags_for(other.reload)

      tax_return.update!(has_dependents: true, paid_over_half_home_costs: false, paid_childcare: false)
      create(:dependent, tax_return: tax_return, ssn: "000770001")

      expect(flags_for(tax_return.reload)).to include("dependent_claimed_elsewhere")
    end

    it "flags a refund that is large for the income reported" do
      low_income = create(:tax_return, :complete, wages: 12_000, withheld: 400, has_dependents: true, paid_over_half_home_costs: false, paid_childcare: false)
      create_list(:dependent, 4, tax_return: low_income)

      # Fake engine: 4 x 1,000 credit + 400 withheld = 4,400 refund on 12,000 income
      expect(flags_for(low_income.reload)).to eq(%w[large_refund_for_income])
    end
  end

  describe "a flagged return" do
    let(:tax_return) { create(:tax_return, :flagged) }
    let(:kase) { tax_return.tax_return_case }

    it "waits for an examiner with a review task" do
      expect(kase).to have_attributes(step: "review_return", outcome: nil, stage: :in_review)
      expect(kase.open_review_task).to be_pending
      # 1,419 tax - 2,650 claimed withholding
      expect(kase.filed_calculation.refund).to eq(1_231)
    end

    it "can be accepted as filed" do
      actions(kase).approve

      expect(kase.reload).to have_attributes(step: "end", outcome: "accepted", status: "closed")
      expect(kase.unresolved_flags).to be_empty
      expect(kase.tasks.first).to have_attributes(status: "completed", assignee_id: examiner.id)
    end

    it "is recalculated when an examiner changes an amount, keeping the filed return intact" do
      adjustment = actions(kase).adjust(field: "colorado_tax_withheld", amount: "1650", reason: "Matches the W-2 on file")

      expect(adjustment).to be_persisted
      expect(adjustment.filed_amount).to eq(2_650)
      expect(kase.reload.filed_calculation.refund).to eq(1_231)
      expect(kase.current_calculation.refund).to eq(231)
      expect(tax_return.reload.income_documents.first.colorado_withholding).to eq(2_650)

      actions(kase).approve
      expect(kase.reload.outcome).to eq("accepted_with_adjustments")
    end

    it "rejects an adjustment with no reason or no change" do
      expect(actions(kase).adjust(field: "colorado_tax_withheld", amount: "1650", reason: "")).not_to be_persisted
      expect(actions(kase).adjust(field: "colorado_tax_withheld", amount: "2650", reason: "Same")).not_to be_persisted
      expect(actions(kase).adjust(field: "not_a_field", amount: "1", reason: "x")).not_to be_persisted
      expect(kase.reload.adjusted_calculation).to be_nil
    end

    it "goes to the taxpayer for information and back to the same examiner" do
      request = actions(kase).request_information("Which amount is on your W-2?")
      expect(kase.reload).to have_attributes(step: "provide_information", stage: :needs_information)
      expect(kase.open_review_task).to be_nil

      taxpayer = ReturnProcessing::TaxpayerActions.new(kase, tax_return.user)
      expect(taxpayer.respond_to_information_request(request, "")).to be(false)
      expect(taxpayer.respond_to_information_request(request, "It says 1,650.")).to be(true)

      expect(kase.reload.step).to eq("review_return")
      expect(kase.open_review_task.assignee_id).to eq(examiner.id)
      expect(kase.open_information_request).to be_nil
    end

    it "writes every action to the audit log with who did it" do
      request = actions(kase).request_information("Which amount is on your W-2?")
      ReturnProcessing::TaxpayerActions.new(kase, tax_return.user).respond_to_information_request(request, "1,650")
      actions(kase).add_note("Taxpayer confirmed the typo.")
      actions(kase).adjust(field: "colorado_tax_withheld", amount: 1_650, reason: "Matches the W-2 on file")
      actions(kase).approve

      lines = kase.audit_lines.order(:created_at)
      expect(lines.pluck(:action)).to eq(%w[
        return.calculated return.screened review.information_requested taxpayer.information_provided
        review.note_added review.adjusted review.approved return.accepted_with_adjustments
      ])
      expect(lines.find_by(action: "review.adjusted")).to have_attributes(actor: examiner)
      expect(lines.find_by(action: "taxpayer.information_provided")).to have_attributes(actor: tax_return.user)
      expect(lines.find_by(action: "return.calculated").actor).to be_nil
    end

    it "keeps personal data out of the audit log" do
      actions(kase).request_information("Which amount is on your W-2?")

      logged = kase.audit_lines.pluck(:data).to_json
      expect(logged).not_to include(tax_return.filer_ssn)
      expect(logged).not_to include("Which amount")
    end
  end
end
