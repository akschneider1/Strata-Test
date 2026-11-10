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

    it "changes an amount, recalculates and accepts" do
      post adjust_tax_return_case_path(kase), params: { return_adjustment: { field: "colorado_tax_withheld", adjusted_amount: "$1,650", reason: "Matches the W-2 on file" } }
      expect(response).to redirect_to(tax_return_case_path(kase))
      expect(kase.reload.current_calculation.refund).to eq(231)

      patch approve_tax_return_case_path(kase)
      expect(kase.reload.outcome).to eq("accepted_with_adjustments")
    end

    it "shows what is wrong with an incomplete adjustment" do
      post adjust_tax_return_case_path(kase), params: { return_adjustment: { field: "", adjusted_amount: "", reason: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Choose the amount to change", "Explain the change")
    end

    it "asks the taxpayer a question and adds notes" do
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
