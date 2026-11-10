# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Taxpayer portal" do
  include Devise::Test::IntegrationHelpers

  let(:taxpayer) { create(:taxpayer) }

  describe "access" do
    it "sends visitors who are not signed in to sign in" do
      get tax_returns_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not let a taxpayer see or change someone else's return" do
      other = create(:tax_return, :submitted)
      sign_in taxpayer

      [ tax_return_path(other), summary_tax_return_path(other), edit_filer_name_tax_return_path(other), new_tax_return_dependent_path(other) ].each do |path|
        get path
        expect(response).to redirect_to(tax_returns_path), "expected #{path} to be refused"
      end
      patch update_filer_name_tax_return_path(other), params: { tax_return: { filer_name_first: "Mallory" } }
      expect(other.reload.filer_name_first).to eq("Tess")
    end

    it "does not let an examiner use the taxpayer portal" do
      sign_in create(:examiner)

      get tax_returns_path
      expect(response).to redirect_to(staff_path)
    end
  end

  describe "filing" do
    before { sign_in taxpayer }

    it "starts one return and resumes it" do
      get tax_returns_path
      expect(response.body).to include("Start my return")

      expect { post tax_returns_path }.to change(TaxReturn, :count).by(1)
      expect { post tax_returns_path }.not_to change(TaxReturn, :count)

      get tax_returns_path
      expect(response).to redirect_to(tax_return_path(taxpayer.tax_returns.first))
    end

    it "saves an answer and moves to the next question" do
      tax_return = create(:tax_return, user: taxpayer)

      patch update_filer_name_tax_return_path(tax_return), params: { tax_return: { filer_name_first: "Tess", filer_name_last: "Payer" } }

      expect(response).to redirect_to(edit_filer_identity_tax_return_path(tax_return))
      expect(tax_return.reload.filer_full_name).to eq("Tess Payer")
    end

    it "shows what to fix, next to the field, when an answer is missing" do
      tax_return = create(:tax_return, user: taxpayer)

      patch update_filer_name_tax_return_path(tax_return), params: { tax_return: { filer_name_first: "", filer_name_last: "Payer" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('<span class="usa-error-message">Enter your first name</span>')
    end

    it "blocks later sections until the earlier ones are done" do
      tax_return = create(:tax_return, user: taxpayer)

      get edit_income_documents_tax_return_path(tax_return)

      expect(response).to redirect_to(tax_return_path(tax_return))
    end

    it "asks about income and support for a dependent who isn't a qualifying child" do
      tax_return = create(:tax_return, :complete, user: taxpayer)
      person = { name_first: "Rosa", name_last: "Payer", relationship: "parent", ssn: "000-00-4444", lived_with_filer_over_half_year: "false", date_of_birth: { month: 4, day: 2, year: 1950 } }

      post tax_return_dependents_path(tax_return), params: { dependent: person }
      rosa = tax_return.dependents.sole
      expect(response).to redirect_to(support_tax_return_dependent_path(tax_return, rosa))

      get support_tax_return_dependent_path(tax_return, rosa)
      expect(response.body).to include("A few more questions about Rosa", "less than $5,200")

      patch update_dependents_tax_return_path(tax_return), params: { tax_return: { has_dependents: "true" } }
      expect(response.body).to include("Answer the remaining questions about each person you added")

      patch update_support_tax_return_dependent_path(tax_return, rosa), params: { dependent: { income_under_limit: "true" } }
      expect(response).to have_http_status(:unprocessable_content)

      patch update_support_tax_return_dependent_path(tax_return, rosa), params: { dependent: { income_under_limit: "true", supported_by_filer: "true" } }
      expect(response).to redirect_to(edit_dependents_tax_return_path(tax_return))
      expect(rosa.reload.qualifies?).to be(true)

      get edit_dependents_tax_return_path(tax_return)
      expect(response.body).to include("Counts as your dependent")
    end

    it "prefills income forms on file and lets the taxpayer confirm them" do
      tax_return = create(:tax_return, :complete, user: taxpayer)
      create(:wage_record, ssn: tax_return.filer_ssn, kind: "form_1099g", payer_name: "CDLE", amount: 900, colorado_withholding: 0)

      get edit_income_documents_tax_return_path(tax_return)
      expect(response.body).to include("CDLE", "Needs your review", "On file with the Department")

      document = tax_return.income_documents.find_by(payer_name: "CDLE")
      patch confirm_tax_return_income_document_path(tax_return, document)
      expect(document.reload.review_status).to eq("confirmed")
    end

    it "does not let a form on file be deleted, only disputed" do
      tax_return = create(:tax_return, :complete, user: taxpayer)
      document = tax_return.income_documents.first

      expect { delete tax_return_income_document_path(tax_return, document) }.not_to change(IncomeDocument, :count)
    end

    it "explains the calculation line by line" do
      tax_return = create(:tax_return, :complete, user: taxpayer)

      get summary_tax_return_path(tax_return)

      expect(response.body).to include("Your filing status: Single", "Colorado income tax", "4.4% of your Colorado taxable income", "$231")
    end

    it "submits a signed return and shows its status" do
      tax_return = create(:tax_return, :complete, user: taxpayer)

      patch submit_tax_return_path(tax_return), params: { tax_return: { declaration_accepted: "1", signature_name: "Tess Payer" } }
      expect(response).to redirect_to(tax_return_path(tax_return))

      follow_redirect!
      expect(response.body).to include("Your return was accepted", tax_return.reload.confirmation_number, "$231")
      expect(response.body).not_to include(tax_return.filer_ssn)
    end

    it "does not submit without a signature" do
      tax_return = create(:tax_return, :complete, user: taxpayer)

      patch submit_tax_return_path(tax_return), params: { tax_return: { declaration_accepted: "0", signature_name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(tax_return.reload).to be_in_progress
    end

    it "accepts a filing when the tax engine is down and processes it later" do
      tax_return = create(:tax_return, :complete, user: taxpayer)
      tax_return.calculate!
      allow(TaxEngine).to receive(:client).and_raise(TaxEngine::Unavailable)

      patch submit_tax_return_path(tax_return), params: { tax_return: { declaration_accepted: "1", signature_name: "Tess Payer" } }
      follow_redirect!

      kase = tax_return.reload.tax_return_case
      expect(tax_return).to be_submitted
      expect(kase).to have_attributes(step: "calculate_return", stage: :received)
      expect(response.body).to include("We got your return", tax_return.confirmation_number, "This page will update on its own", "$231")

      allow(TaxEngine).to receive(:client).and_call_original
      expect(ReturnProcessing.process_pending).to eq(1)
      expect(kase.reload).to have_attributes(step: "end", outcome: "accepted")
    end

    it "shows the checklist without an estimate when the tax engine is down" do
      tax_return = create(:tax_return, :complete, user: taxpayer)
      allow(TaxEngine).to receive(:client).and_raise(TaxEngine::Unavailable)

      get tax_return_path(tax_return)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("show your estimate right now", "Review and sign")
    end

    it "lets the taxpayer answer an examiner's question" do
      tax_return = create(:tax_return, :flagged, user: taxpayer)
      ReturnProcessing::ExaminerActions.new(tax_return.tax_return_case, create(:examiner)).request_information("Which amount is on your W-2?")

      get tax_return_path(tax_return)
      expect(response.body).to include("We have a question about your return", "Which amount is on your W-2?")

      patch respond_tax_return_path(tax_return), params: { information_request: { response: "It says 1,650." } }
      expect(tax_return.tax_return_case.reload.step).to eq("review_return")
    end

    it "serves the interview in Spanish" do
      tax_return = create(:tax_return, user: taxpayer)

      get edit_filer_name_tax_return_path(tax_return, locale: "es-US")

      expect(response.body).to include("¿Cuál es su nombre?")
    end
  end
end
