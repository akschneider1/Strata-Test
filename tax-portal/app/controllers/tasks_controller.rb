# frozen_string_literal: true

# The examiner work queue (list, filters, "pick up next task") comes from
# the Strata SDK. Opening a task goes straight to the return under review.
class TasksController < Strata::TasksController
  def show
    redirect_to tax_return_case_path(@task.case_id)
  end
end
