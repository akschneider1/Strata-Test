# frozen_string_literal: true

# Examiner view of a return in processing, and the actions an examiner can
# take on it.
class TaxReturnCasesController < StaffController
  before_action :set_case, except: [ :index, :closed ]

  rescue_from ReturnProcessing::ExaminerActions::NotUnderReview do
    redirect_to tax_return_case_path(@case), alert: t("tax_return_cases.errors.not_under_review")
  end
  rescue_from ReturnProcessing::ExaminerActions::NotAssigned do
    redirect_to tax_return_case_path(@case), alert: t("tax_return_cases.errors.not_assigned")
  end
  rescue_from ReturnProcessing::ExaminerActions::SameExaminer do
    redirect_to tax_return_case_path(@case), alert: t("tax_return_cases.errors.same_examiner")
  end
  rescue_from TaxEngine::Error do
    redirect_to tax_return_case_path(@case), alert: t("tax_return_cases.errors.tax_engine_unavailable")
  end

  def index
    @cases = paginate(visible_cases.submitted.where(status: :open)).includes(:tax_return, :review_flags).newest_first
    @showing = :open
  end

  def closed
    @cases = paginate(visible_cases.where(status: :closed)).includes(:tax_return, :review_flags).newest_first
    @showing = :closed
    render :index
  end

  def show
    load_case_details
    @adjustment = ReturnAdjustment.new(tax_return_case: @case)
    @information_request = InformationRequest.new(tax_return_case: @case)
    @note = CaseNote.new(tax_return_case: @case)
  end

  def assign_to_me
    actions.assign_to_me
    redirect_to tax_return_case_path(@case)
  end

  def approve
    sent_on = actions.approve == :second_review
    redirect_to tax_return_case_path(@case), notice: t(sent_on ? ".sent_for_confirmation" : ".approved")
  end

  # Propose not accepting the return. A second examiner confirms.
  def reject
    if actions.reject(params.dig(:rejection, :reason))
      redirect_to tax_return_case_path(@case), notice: t(".sent_for_confirmation")
    else
      redirect_to tax_return_case_path(@case, anchor: "reject"), alert: t(".reason_needed")
    end
  end

  def confirm
    actions.confirm
    redirect_to tax_return_case_path(@case), notice: t(".confirmed")
  end

  def send_back
    if actions.send_back(params.dig(:send_back, :note))
      redirect_to tax_return_case_path(@case), notice: t(".sent_back")
    else
      redirect_to tax_return_case_path(@case), alert: t(".note_needed")
    end
  end

  def adjust
    attributes = params.require(:return_adjustment).permit(:field, :adjusted_amount, :reason)
    @adjustment = actions.adjust(
      field: attributes[:field], amount: attributes[:adjusted_amount].to_s.delete("$, ").presence, reason: attributes[:reason]
    )
    return redirect_to(tax_return_case_path(@case), notice: t(".adjusted")) if @adjustment.persisted?

    rerender_with(information_request: InformationRequest.new(tax_return_case: @case), note: CaseNote.new(tax_return_case: @case))
  end

  def request_information
    @information_request = actions.request_information(params.require(:information_request).permit(:question)[:question])
    return redirect_to(tax_return_case_path(@case), notice: t(".requested")) if @information_request.persisted?

    rerender_with(adjustment: ReturnAdjustment.new(tax_return_case: @case), note: CaseNote.new(tax_return_case: @case))
  end

  def add_note
    @note = actions.add_note(params.require(:case_note).permit(:body)[:body])
    return redirect_to(tax_return_case_path(@case, anchor: "notes")) if @note.persisted?

    rerender_with(adjustment: ReturnAdjustment.new(tax_return_case: @case), information_request: InformationRequest.new(tax_return_case: @case))
  end

  private

  def set_case
    @case = visible_cases.find(params[:id])
  end

  def actions
    ReturnProcessing::ExaminerActions.new(@case, current_user)
  end

  def load_case_details
    @tax_return = @case.tax_return
    @calculation = @case.current_calculation
    @filed_calculation = @case.filed_calculation
    @flags = @case.review_flags.order(:created_at)
    @income_documents = @tax_return.income_documents.includes(:wage_record).in_display_order
    @task = @case.open_task
    @history = @case.audit_lines.order(:created_at).includes(:actor)
  end

  def rerender_with(adjustment: @adjustment, information_request: @information_request, note: @note)
    load_case_details
    @adjustment = adjustment
    @information_request = information_request
    @note = note
    render :show, status: :unprocessable_content
  end
end
