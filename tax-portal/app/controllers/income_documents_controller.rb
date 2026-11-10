# frozen_string_literal: true

# The income forms on a return. Forms already on file with the Department
# are confirmed, corrected or disputed; others can be added by hand.
class IncomeDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax_return
  before_action :set_income_document, only: [ :edit, :update, :destroy, :confirm, :dispute ]

  def new
    @income_document = @tax_return.income_documents.new(kind: params[:kind].presence_in(IncomeDocument::KINDS) || "w2")
  end

  def create
    @income_document = @tax_return.income_documents.new(income_document_params.merge(source: "taxpayer", review_status: "entered"))
    if @income_document.save
      redirect_to edit_income_documents_tax_return_path(@tax_return)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    saved = if @income_document.on_file?
      @income_document.correct!(income_document_params.slice(:amount, :colorado_withholding))
    else
      @income_document.update(income_document_params)
    end

    if saved
      redirect_to edit_income_documents_tax_return_path(@tax_return)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def confirm
    @income_document.confirm! if @income_document.on_file?
    redirect_to edit_income_documents_tax_return_path(@tax_return)
  end

  def dispute
    @income_document.dispute! if @income_document.on_file?
    redirect_to edit_income_documents_tax_return_path(@tax_return)
  end

  # Only forms the taxpayer typed in can be removed. A form on file is
  # disputed instead, so the Department can follow up.
  def destroy
    @income_document.destroy! unless @income_document.on_file?
    redirect_to edit_income_documents_tax_return_path(@tax_return)
  end

  private

  def set_tax_return
    @tax_return = TaxReturn.find(params[:tax_return_id])
    authorize @tax_return, :update?
  end

  def set_income_document
    @income_document = @tax_return.income_documents.find(params[:id])
  end

  def income_document_params
    permitted = params.require(:income_document).permit(:kind, :owner, :payer_name, :amount, :colorado_withholding)
    permitted[:owner] = "filer" unless @tax_return.joint?
    %i[amount colorado_withholding].each do |field|
      permitted[field] = permitted[field].to_s.delete("$, ").presence if permitted.key?(field)
    end
    permitted[:colorado_withholding] ||= 0 if permitted.key?(:amount)
    permitted
  end
end
