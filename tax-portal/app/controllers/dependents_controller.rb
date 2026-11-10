# frozen_string_literal: true

# Add, change or remove the dependents on a return. Part of the Family
# section; always returns to the dependents page of the interview.
class DependentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax_return
  before_action :set_dependent, only: [ :edit, :update, :destroy ]

  def new
    @dependent = @tax_return.dependents.new
  end

  def create
    @dependent = @tax_return.dependents.new(dependent_params)
    if @dependent.save
      @tax_return.update!(has_dependents: true)
      redirect_to edit_dependents_tax_return_path(@tax_return)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @dependent.update(dependent_params)
      redirect_to edit_dependents_tax_return_path(@tax_return)
    else
      render :edit, status: :unprocessable_content
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

  def dependent_params
    params.require(:dependent).permit(
      :name_first, :name_last, :relationship, :ssn, :lived_with_filer_over_half_year, :full_time_student, :disabled,
      date_of_birth: [ :month, :day, :year ]
    )
  end
end
