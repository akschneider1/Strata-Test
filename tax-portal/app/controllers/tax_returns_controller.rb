# frozen_string_literal: true

# The taxpayer's return: checklist, interview pages (generated from
# TaxReturnFlow), the calculation, review and signature, and status after
# filing.
class TaxReturnsController < ApplicationController
  include Strata::Flows::ApplicationFormController

  before_action :authenticate_user!
  before_action :set_tax_return, except: [ :index, :create ]
  flow TaxReturnFlow
  layout "tax_return_form", only: TaxReturnFlow.generated_routes
  before_action :authorize_update, only: TaxReturnFlow.generated_routes
  before_action :prefill_income_documents, only: [ :edit_income_documents ]

  rescue_from TaxEngine::Error, with: :tax_engine_unavailable

  def index
    @tax_return = policy_scope(TaxReturn).find_by(tax_year: TaxReturn::CURRENT_TAX_YEAR)
    authorize TaxReturn
    redirect_to tax_return_path(@tax_return) if @tax_return
  end

  def create
    authorize TaxReturn
    tax_return = TaxReturn.find_or_create_by!(user: current_user, tax_year: TaxReturn::CURRENT_TAX_YEAR)
    redirect_to tax_return_path(tax_return)
  end

  # In progress: the checklist. After filing: where the return stands.
  def show
    authorize @tax_return
    if @tax_return.submitted?
      @case = @tax_return.tax_return_case
      @calculation = @case.current_calculation
      @information_request = @case.open_information_request
      render :status
    else
      @calculation = @tax_return.calculate! if @tax_return.ready_to_calculate?
    end
  end

  # "How we calculated this": every line, in plain language.
  def summary
    authorize @tax_return
    return redirect_to(tax_return_path(@tax_return)) unless @tax_return.submitted? || @tax_return.ready_to_calculate?

    @calculation = @tax_return.submitted? ? @tax_return.tax_return_case.current_calculation : @tax_return.calculate!
    @filed_calculation = @tax_return.tax_return_case.filed_calculation if @tax_return.submitted?
  end

  def review
    authorize @tax_return
    return redirect_to(tax_return_path(@tax_return)) unless @flow.completed?

    @calculation = @tax_return.calculate!
  end

  def submit
    authorize @tax_return
    return redirect_to(tax_return_path(@tax_return)) unless @flow.completed?

    @tax_return.assign_attributes(params.require(:tax_return).permit(:declaration_accepted, :signature_name))
    # Processing runs within this request. Strata logs a failed processing
    # step instead of raising, so check that the case moved on; if it didn't
    # (for example the tax engine is down), undo the submission so nothing is
    # half-filed and the taxpayer can try again.
    stalled = false
    submitted = TaxReturn.transaction(requires_new: true) do
      raise ActiveRecord::Rollback unless @tax_return.submit_application

      stalled = @tax_return.tax_return_case.reload.processing_stalled?
      raise ActiveRecord::Rollback if stalled

      true
    end
    raise TaxEngine::Unavailable, "Return processing did not complete" if stalled

    if submitted
      redirect_to tax_return_path(@tax_return), notice: t(".submitted")
    else
      @calculation = @tax_return.calculate!
      render :review, status: :unprocessable_content
    end
  end

  # The taxpayer answers an examiner's question.
  def respond
    authorize @tax_return
    kase = @tax_return.tax_return_case
    request = kase.open_information_request
    return redirect_to(tax_return_path(@tax_return)) unless request

    response = params.require(:information_request).permit(:response)[:response]
    if ReturnProcessing::TaxpayerActions.new(kase, current_user).respond_to_information_request(request, response)
      redirect_to tax_return_path(@tax_return), notice: t(".sent")
    else
      @case = kase
      @calculation = kase.current_calculation
      @information_request = request
      render :status, status: :unprocessable_content
    end
  end

  def flow_record
    @tax_return
  end

  # Called by the flow when a page fails validation. Field errors are shown
  # next to each field, so don't repeat them in a banner.
  def on_flow_update_invalid
  end

  private

  def set_tax_return
    @tax_return = TaxReturn.find(params[:id])
  end

  def authorize_update
    authorize @tax_return, :update?
  end

  def prefill_income_documents
    RecordsOnFile.prefill(@tax_return)
  end

  def tax_engine_unavailable(error)
    Rails.logger.error("Tax engine error: #{error.class.name}")
    redirect_to tax_return_path(@tax_return), alert: t("tax_returns.errors.tax_engine_unavailable")
  end
end
