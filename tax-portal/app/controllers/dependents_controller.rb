# frozen_string_literal: true

# Add, change or remove the dependents on a return. Part of the Family
# section; always returns to the dependents page of the interview.
class DependentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax_return
  before_action :set_dependent, only: [ :edit, :update, :destroy, :support, :update_support ]

  rescue_from TaxEngine::Error do
    redirect_to edit_dependents_tax_return_path(@tax_return), alert: t("tax_returns.errors.tax_engine_unavailable")
  end

  def new
    @dependent = @tax_return.dependents.new
  end

  def create
    @dependent = @tax_return.dependents.new(dependent_params)
    if @dependent.save
      @tax_return.update!(has_dependents: true)
      redirect_to next_step
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @dependent.update(dependent_params)
      redirect_to next_step
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Two more questions for someone who isn't a qualifying child: their
  # income and who supported them.
  def support
    return redirect_to(edit_dependents_tax_return_path(@tax_return)) unless @dependent.needs_support_questions?

    @income_limit = TaxEngine.qualifying_relative_income_limit(@tax_return.tax_year)
  end

  def update_support
    @dependent.assign_attributes(params.fetch(:dependent, {}).permit(:income_under_limit, :supported_by_filer))
    if @dependent.save(context: :support)
      redirect_to edit_dependents_tax_return_path(@tax_return)
    else
      @income_limit = TaxEngine.qualifying_relative_income_limit(@tax_return.tax_year)
      render :support, status: :unprocessable_content
    end
  end

  def destroy
    @dependent.destroy!
    redirect_to edit_dependents_tax_return_path(@tax_return)
  end

  private

  def set_tax_return
    @tax_return = TaxReturn.find(params[:tax_return_id])
    authorize @tax_return, :update?
  end

  def set_dependent
    @dependent = @tax_return.dependents.find(params[:id])
  end

  # Ask the income and support questions when they apply and are unanswered.
  def next_step
    if @dependent.support_questions_answered?
      edit_dependents_tax_return_path(@tax_return)
    else
      support_tax_return_dependent_path(@tax_return, @dependent)
    end
  end

  def dependent_params
    params.require(:dependent).permit(
      :name_first, :name_last, :relationship, :ssn, :lived_with_filer_over_half_year, :full_time_student, :disabled,
      date_of_birth: [ :month, :day, :year ]
    )
  end
end
