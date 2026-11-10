# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewTask do
  it "is a Strata task with a due date a week out" do
    kase = create(:tax_return, :flagged).tax_return_case
    task = kase.open_review_task

    expect(task).to be_a(Strata::Task)
    expect(task.due_on).to eq(7.days.from_now.to_date)
  end
end
