# frozen_string_literal: true

require 'rails_helper'

# With the fake tax engine: (income - 15,750) x 4.4% tax, minus withholding.
RSpec.describe ServiceMeasures do
  subject(:measures) { described_class.new }

  let(:examiner) { create(:examiner) }

  def actions(kase, user = examiner)
    ReturnProcessing::ExaminerActions.new(kase, user).tap do |actions|
      actions.assign_to_me if kase.step == "review_return" && kase.open_task&.assignee_id.nil?
    end
  end

  it "reports nothing when no returns are filed" do
    create(:tax_return, :complete)

    expect(measures).to have_attributes(
      filed: 0, decided: 0, flagged: 0, flags_by_code: [], returns_adjusted: 0, net_change_from_adjustments: 0,
      median_time_to_decision_automatic: nil, median_time_to_answer: nil, oldest_open_question_asked_at: nil
    )
    expect(measures.share(0)).to be_nil
  end

  it "separates returns accepted automatically from returns sent to an examiner" do
    create(:tax_return, :submitted)
    create(:tax_return, :submitted)
    create(:tax_return, :flagged)

    expect(measures).to have_attributes(
      filed: 3, decided: 2, accepted_automatically: 2, flagged: 1, in_review: 1, waiting_on_taxpayer: 0,
      accepted_after_review: 0, accepted_with_adjustments: 0
    )
    expect(measures.share(measures.accepted_automatically)).to eq(67)
    expect(measures.flags_by_code).to eq([ [ "withholding_higher_than_record", 1 ] ])
    expect(measures.median_time_to_decision_automatic).to be_between(0, 60)
    expect(measures.median_time_to_decision_reviewed).to be_nil
  end

  it "follows a reviewed return through a question, an adjustment and acceptance" do
    kase = create(:tax_return, :flagged).tax_return_case
    filed_refund = kase.filed_calculation.refund

    request = actions(kase).request_information("Which amount is on your W-2?")
    expect(described_class.new).to have_attributes(waiting_on_taxpayer: 1, questions_asked: 1, questions_open: 1)
    expect(described_class.new.oldest_open_question_asked_at).to be_within(1.second).of(request.created_at)

    ReturnProcessing::TaxpayerActions.new(kase, kase.tax_return.user).respond_to_information_request(request, "The lower one.")
    kase.reload
    actions(kase).adjust(field: "colorado_tax_withheld", amount: 1_650, reason: "Matches the W-2 on file.")
    actions(kase.reload).approve
    expect(described_class.new).to have_attributes(second_review: 1, decided: 0)
    actions(kase.reload, create(:examiner)).confirm

    after = described_class.new
    expect(after).to have_attributes(
      decided: 1, flagged: 1, accepted_automatically: 0, accepted_with_adjustments: 1, in_review: 0,
      questions_open: 0, returns_adjusted: 1
    )
    expect(after.net_change_from_adjustments).to eq(kase.reload.adjusted_calculation.refund - filed_refund)
    expect(after.net_change_from_adjustments).to eq(-1_000)
    expect(after.median_time_to_answer).to be >= 0
    expect(after.median_time_to_decision_reviewed).to be >= 0
  end
end
