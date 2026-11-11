# frozen_string_literal: true

# The examiner work queue (list, filters, "pick up next task") comes from
# the Strata SDK. Opening a task goes straight to the return under review.
class TasksController < Strata::TasksController
  def show
    redirect_to tax_return_case_path(@task.case_id)
  end

  # "Pick up next" from the tasks this examiner can see.
  def pick_up_next_task
    task = Strata::Task.transaction do
      visible_tasks.incomplete.unassigned.lock.first&.tap { |next_task| next_task.assign(current_user.id) }
    end

    if task
      flash["task-message"] = I18n.t("strata.tasks.messages.task_picked_up")
      redirect_to url_for(action: :show, id: task.id)
    else
      flash["task-message"] = I18n.t("strata.tasks.messages.no_tasks_available")
      redirect_to url_for(action: :index)
    end
  end

  protected

  def tasks_index_locals
    super.merge(unassigned_tasks: visible_tasks.incomplete.unassigned, task_row_component_class: TaxReturnTaskRowComponent)
  end

  # The Strata list, limited to what this examiner can see, one page at a time.
  def filter_tasks
    paginate(super.where(case_id: DemoMode.case_ids_for(current_user)))
  end

  def set_task
    @task = visible_tasks.find(params[:id]) if params[:id].present?
  end
end
