# frozen_string_literal: true

# Base controller for the examiner portal. Everything under /staff requires
# a signed-in examiner.
class StaffController < Strata::StaffController
  layout "staff"

  before_action :authenticate_user!
  before_action :authorize_staff
  # Access is decided for the whole staff area by StaffPolicy, so there is
  # no per-record scope to verify on index pages.
  skip_after_action :verify_policy_scoped

  def index
    @open_tasks = Strata::Task.incomplete
    @my_tasks = @open_tasks.where(assignee_id: current_user.id)
    @cases_by_step = TaxReturnCase.submitted.group(:business_process_current_step).count
    @accepted_automatically = TaxReturnCase.where(outcome: "accepted").where.missing(:review_flags).count
    @recent_activity = Strata::AuditLine.where(subject_type: "TaxReturnCase").order(created_at: :desc).limit(8)
  end

  def measures
    @measures = ServiceMeasures.new
  end

  protected

  def case_classes
    [ TaxReturnCase ]
  end

  def cases_links
    [
      { name: t("staff.header.returns"), path: tax_return_cases_path },
      { name: t("staff.header.measures"), path: staff_measures_path }
    ]
  end

  # Shows one page of a long list. The staff layout adds the page links.
  def paginate(scope)
    @pagination = Pagination.new(page: params[:page], total: scope.count)
    @pagination.apply(scope)
  end

  private

  def authorize_staff
    authorize :staff, :access?
  end
end
