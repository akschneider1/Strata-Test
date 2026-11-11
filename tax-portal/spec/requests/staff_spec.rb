# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Examiner portal" do
  include Devise::Test::IntegrationHelpers

  let(:examiner) { create(:examiner) }
  let(:kase) { create(:tax_return, :flagged).tax_return_case }

  describe "access" do
    it "is closed to taxpayers and visitors" do
      paths = [ staff_path, staff_measures_path, tasks_path, tax_return_cases_path, tax_return_case_path(kase) ]

      paths.each do |path|
        get path
        expect(response).to redirect_to(new_user_session_path), "expected #{path} to require sign-in"
      end

      sign_in kase.tax_return.user
      paths.each do |path|
        get path
        expect(response).to redirect_to(tax_returns_path), "expected #{path} to be refused to a taxpayer"
      end
      patch approve_tax_return_case_path(kase)
      expect(kase.reload.step).to eq("review_return")
    end
  end

  describe "working a return" do
    before { sign_in examiner }

    it "shows the dashboard and the work queue" do
      kase
      get staff_path
      expect(response.body).to include("Examiner dashboard", "Waiting to be picked up")

      get tasks_path
      expect(response.body).to include("Review flagged return")
    end

    it "shows long lists one page at a time" do
      stub_const("Pagination::PER_PAGE", 2)
      3.times { create(:tax_return, :submitted) }
      newest = TaxReturnCase.newest_first.first.tax_return.confirmation_number

      get closed_tax_return_cases_path
      expect(response.body).to include("Showing 1 to 2 of 3", "Next page", newest)
      expect(response.body.scan("<tr>").size).to eq(3)

      get closed_tax_return_cases_path(page: 2)
      expect(response.body).to include("Showing 3 to 3 of 3", "Previous page")
      expect(response.body).not_to include(newest)

      get closed_tax_return_cases_path(page: 99)
      expect(response.body).to include("Showing 3 to 3 of 3")

      3.times { create(:tax_return, :flagged) }
      get tasks_path
      expect(response.body).to include("Showing 1 to 2 of 3")
    end

    it "shows service measures" do
      get staff_measures_path
      expect(response.body).to include("No returns have been filed yet.")

      kase
      create(:tax_return, :submitted)
      get staff_measures_path
      expect(response.body).to include("Service measures", "Accepted with no review", "1 (50%)", "Withholding higher than reported by payer")
    end

    it "picks up the next return and opens it" do
      kase
      post pick_up_next_task_tasks_path
      task = kase.reload.open_review_task

      expect(task.assignee_id).to eq(examiner.id)
      expect(response).to redirect_to(task_path(task))
      follow_redirect!
      expect(response).to redirect_to(tax_return_case_path(kase))
    end

    it "shows why the return was flagged, with reported and on-file amounts" do
      get tax_return_case_path(kase)

      expect(response.body).to include("Withholding higher than reported by payer", "$2,650", "$1,650", "Tess Payer")
      expect(response.body).not_to include(kase.tax_return.filer_ssn)
    end

    it "does not act on a return until the examiner has picked it up" do
      post adjust_tax_return_case_path(kase), params: { return_adjustment: { field: "colorado_tax_withheld", adjusted_amount: "1650", reason: "Matches the W-2 on file" } }
      follow_redirect!
      expect(response.body).to include("assigned to you", "No one has picked up this return")
      expect(kase.reload.return_adjustments).to be_empty

      patch approve_tax_return_case_path(kase)
      expect(kase.reload.step).to eq("review_return")
    end

    it "takes a second examiner to confirm a large change" do
      patch assign_to_me_tax_return_case_path(kase)
      post adjust_tax_return_case_path(kase), params: { return_adjustment: { field: "colorado_tax_withheld", adjusted_amount: "$1,650", reason: "Matches the W-2 on file" } }
      expect(response).to redirect_to(tax_return_case_path(kase))
      expect(kase.reload.current_calculation.refund).to eq(231)

      get tax_return_case_path(kase)
      expect(response.body).to include("a second examiner will confirm")

      patch approve_tax_return_case_path(kase)
      expect(kase.reload).to have_attributes(step: "second_review", outcome: nil)

      patch confirm_tax_return_case_path(kase)
      follow_redirect!
      expect(response.body).to include("a different examiner has to confirm it")
      expect(kase.reload.step).to eq("second_review")

      sign_in create(:examiner, full_name: "Second Examiner")
      get tax_return_case_path(kase)
      expect(response.body).to include("proposes accepting this return with adjustments", "Confirm")
      patch confirm_tax_return_case_path(kase)
      expect(kase.reload).to have_attributes(step: "end", outcome: "accepted_with_adjustments")
    end

    it "does not accept a return, with a reason the taxpayer sees" do
      patch assign_to_me_tax_return_case_path(kase)
      post reject_tax_return_case_path(kase), params: { rejection: { reason: "" } }
      expect(kase.reload.step).to eq("review_return")

      post reject_tax_return_case_path(kase), params: { rejection: { reason: "The W-2 belongs to a different person. File again with your own W-2." } }
      expect(kase.reload.step).to eq("second_review")

      sign_in create(:examiner)
      patch confirm_tax_return_case_path(kase)
      expect(kase.reload).to have_attributes(step: "end", outcome: "not_accepted", stage: :not_accepted)

      sign_in kase.tax_return.user
      get tax_return_path(kase.tax_return)
      expect(response.body).to include("We could not accept your return", "The W-2 belongs to a different person.")
      expect(response.body).not_to include("Your refund")
    end

    it "lets the second examiner send a proposal back with a note" do
      patch assign_to_me_tax_return_case_path(kase)
      post reject_tax_return_case_path(kase), params: { rejection: { reason: "Not processable." } }

      sign_in create(:examiner)
      post send_back_tax_return_case_path(kase), params: { send_back: { note: "" } }
      expect(kase.reload.step).to eq("second_review")

      post send_back_tax_return_case_path(kase), params: { send_back: { note: "Ask the taxpayer first." } }
      expect(kase.reload).to have_attributes(step: "review_return", proposed_outcome: nil)
      expect(kase.open_task).to have_attributes(class: ReviewTask, assignee_id: examiner.id)
      expect(kase.case_notes.pluck(:body)).to eq([ "Ask the taxpayer first." ])
    end

    it "changes an amount, recalculates and accepts a small change alone" do
      patch assign_to_me_tax_return_case_path(kase)
      post adjust_tax_return_case_path(kase), params: { return_adjustment: { field: "colorado_tax_withheld", adjusted_amount: "$2,400", reason: "Matches the corrected W-2" } }
      expect(kase.reload.current_calculation.refund).to eq(981)

      patch approve_tax_return_case_path(kase)
      expect(kase.reload.outcome).to eq("accepted_with_adjustments")
    end

    it "shows what is wrong with an incomplete adjustment" do
      patch assign_to_me_tax_return_case_path(kase)
      post adjust_tax_return_case_path(kase), params: { return_adjustment: { field: "", adjusted_amount: "", reason: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Choose the amount to change", "Explain why you changed the amount")
    end

    it "asks the taxpayer a question and adds notes" do
      patch assign_to_me_tax_return_case_path(kase)
      post request_information_tax_return_case_path(kase), params: { information_request: { question: "Which amount is on your W-2?" } }
      expect(kase.reload.step).to eq("provide_information")

      post add_note_tax_return_case_path(kase), params: { case_note: { body: "Waiting on the taxpayer." } }
      expect(kase.case_notes.pluck(:body)).to eq([ "Waiting on the taxpayer." ])

      patch approve_tax_return_case_path(kase)
      expect(response).to redirect_to(tax_return_case_path(kase))
      expect(kase.reload.step).to eq("provide_information")
    end

    it "lists open and closed returns" do
      closed = create(:tax_return, :submitted)
      kase

      get tax_return_cases_path
      expect(response.body).to include(kase.tax_return.confirmation_number)
      expect(response.body).not_to include(closed.confirmation_number)

      get closed_tax_return_cases_path
      expect(response.body).to include(closed.confirmation_number, "Accepted as filed")
    end
  end
end
