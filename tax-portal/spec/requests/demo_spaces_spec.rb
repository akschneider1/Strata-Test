# frozen_string_literal: true

require 'rails_helper'

# Each visitor to the demo has a private copy of the demo people.
RSpec.describe "A visitor's own copy of the demo" do
  include ActiveSupport::Testing::TimeHelpers

  before { allow(DemoMode).to receive(:enabled?).and_return(true) }

  # A second browser: its own cookies, so its own copy.
  def visitor
    open_session { |session| session.host! "www.example.com" }
  end

  def continue_as(session, person)
    session.delete demo_sign_out_path
    session.post demo_sign_in_path(person: person)
  end

  def jordans_case(space)
    space.person(:jordan).tax_returns.sole.tax_return_case
  end

  it "gives each visitor their own people, and the same visitor the same copy" do
    first = visitor
    second = visitor
    continue_as(first, "maya")
    continue_as(second, "maya")
    continue_as(first, "daniela")

    expect(DemoSpace.count).to eq(2)
    expect(User.where(full_name: "Maya Torres").count).to eq(2)
    expect(User.where(full_name: "Maya Torres").pluck(:demo_space_id).uniq.size).to eq(2)
  end

  it "fills in a visitor's forms from the records in their own copy" do
    first = visitor
    continue_as(first, "maya")
    continue_as(visitor, "maya")
    space = DemoSpace.order(:created_at).first

    tax_return = TaxReturn.create!(user: space.person(:maya), filer_ssn: "000001001", **DemoData::ADDRESS)
    documents = RecordsOnFile.prefill(tax_return)

    expect(documents.map(&:payer_name)).to eq([ "Front Range Outfitters" ])
    expect(documents.sole.wage_record.demo_space_id).to eq(space.id)
  end

  it "doesn't flag a dependent because another visitor's copy claims the same child" do
    continue_as(visitor, "daniela")
    continue_as(visitor, "daniela")

    DemoSpace.find_each do |space|
      tax_return = DemoData.new(space).submit(space.person(:daniela).tax_returns.sole)
      expect(tax_return.tax_return_case.review_flags.pluck(:code)).not_to include("dependent_claimed_elsewhere")
    end
  end

  describe "an examiner" do
    let(:mine) { visitor }
    let(:theirs) { visitor }
    let(:my_space) { DemoSpace.order(:created_at).first }
    let(:their_space) { DemoSpace.order(:created_at).last }

    before do
      continue_as(mine, "examiner")
      continue_as(theirs, "examiner")
    end

    it "sees only the returns, tasks and measures in their copy" do
      mine.get tax_return_cases_path
      expect(mine.response.body).to include(jordans_case(my_space).tax_return.confirmation_number)
      expect(mine.response.body).not_to include(jordans_case(their_space).tax_return.confirmation_number)

      mine.get staff_path
      expect(mine.response.body).to include('data-testid="stat-unassigned"').or include("unassigned")
      expect(mine.controller.view_assigns["open_tasks"].count).to eq(1)

      mine.get staff_measures_path
      expect(mine.controller.view_assigns["measures"].filed).to eq(3)

      mine.get tasks_path
      expect(mine.controller.view_assigns["tasks"].map(&:case_id)).to eq([ jordans_case(my_space).id ])
    end

    it "can't open a return or a task from another copy" do
      mine.get tax_return_case_path(jordans_case(their_space))
      expect(mine.response).to have_http_status(:not_found)

      mine.get task_path(jordans_case(their_space).tasks.sole)
      expect(mine.response).to have_http_status(:not_found)
    end

    it "picks up the next return from their own copy only" do
      Strata::Task.where(case_id: jordans_case(my_space).id).delete_all

      mine.post pick_up_next_task_tasks_path

      expect(jordans_case(their_space).tasks.sole.assignee_id).to be_nil
    end

    it "settling a return in one copy leaves the other waiting" do
      mine.post pick_up_next_task_tasks_path
      kase = jordans_case(my_space)
      expect(kase.tasks.sole.assignee_id).to eq(my_space.person(:examiner).id)
      ReturnProcessing::ExaminerActions.new(kase, my_space.person(:examiner)).approve

      expect(kase.reload.outcome).to eq("accepted")
      expect(jordans_case(their_space).reload).to have_attributes(outcome: nil, step: "review_return")
    end
  end

  describe "starting over" do
    it "discards only the visitor's own copy" do
      first = visitor
      second = visitor
      continue_as(first, "maya")
      continue_as(second, "maya")
      kept = DemoSpace.order(:created_at).last

      first.post demo_reset_path
      first.follow_redirect!

      expect(first.response.body).to include("Your demo is back to the start.")
      expect(DemoSpace.all.to_a).to eq([ kept ])
      expect(User.count).to eq(7)
      expect(WageRecord.count).to eq(DemoData::WAGE_RECORDS.size)
      expect(TaxReturn.count).to eq(4)

      continue_as(first, "maya")
      expect(DemoSpace.count).to eq(2)
      expect(first.response.location).to end_with(tax_returns_path)
    end

    it "leaves nothing behind" do
      first = visitor
      continue_as(first, "examiner")
      first.post demo_reset_path

      [ User, TaxReturn, TaxReturnCase, Strata::Task, ReviewFlag, WageRecord, IncomeDocument, Dependent, DemoSpace ].each do |model|
        expect(model.unscoped.count).to eq(0), "#{model} rows were left behind"
      end
    end
  end

  describe "a copy nobody is using" do
    it "is discarded after two hours, and the visitor starts fresh" do
      first = visitor
      continue_as(first, "maya")
      old = DemoSpace.sole

      travel 3.hours do
        first.get tax_returns_path
        first.follow_redirect! while first.response.redirect?
        expect(first.request.path).to eq(root_path)
        expect(first.response.body).to include("Continue as Maya")
        expect(first.response.body).not_to include("Reset the demo")
        expect(DemoSpace.exists?(old.id)).to be(false)

        continue_as(first, "maya")
        expect(DemoSpace.count).to eq(1)
      end
    end

    it "is kept while it is in use" do
      first = visitor
      continue_as(first, "maya")

      # Still signed in after an hour and a half of someone talking.
      travel(90.minutes) do
        first.get tax_returns_path
        expect(first.response).to have_http_status(:ok)
      end
      travel(3.hours) do
        first.get tax_returns_path
        expect(first.response).to have_http_status(:ok)
        expect(DemoSpace.count).to eq(1)
      end
    end

    it "is cleared out when the next visitor arrives" do
      continue_as(visitor, "maya")

      travel(3.hours) { continue_as(visitor, "maya") }

      expect(DemoSpace.count).to eq(1)
    end
  end

  it "leaves people who aren't demo people alone" do
    continue_as(visitor, "examiner")
    examiner = User.create!(uid: "real-examiner", provider: "login.gov", email: "examiner@example.com", full_name: "Real Examiner", role: :examiner, mfa_preference: :opt_out)

    expect(DemoMode.cases_for(examiner)).to be_empty
    expect(DemoMode.tasks_for(examiner)).to be_empty

    DemoSpace.discard_all
    expect(User.all.to_a).to eq([ examiner ])
  end
end
