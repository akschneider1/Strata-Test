# frozen_string_literal: true

# One row of the examiner work queue. The Strata SDK's row shows a case ID;
# an examiner needs to see whose return it is and who has it.
class TaxReturnTaskRowComponent < Strata::Tasks::TaskRowComponent
  def self.columns
    %i[taxpayer confirmation type assignee due_date created_date]
  end

  protected

  def taxpayer
    link_to tax_return.filer_full_name, helpers.url_for(only_path: true, action: :show, id: @task.id.to_s)
  end

  def confirmation
    tax_return.confirmation_number
  end

  def type
    I18n.t("tasks.types.#{@task.type.underscore}")
  end

  def assignee
    @task.assignee_id ? User.find_by(id: @task.assignee_id)&.display_name : I18n.t("staff.unassigned")
  end

  def sort_value_for(column)
    case column.to_sym
    when :taxpayer then tax_return.filer_full_name
    when :confirmation then confirmation
    when :assignee then assignee
    else super
    end
  end

  private

  def tax_return
    @task.case.tax_return
  end
end
