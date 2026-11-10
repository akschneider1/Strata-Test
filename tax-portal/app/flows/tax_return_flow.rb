# frozen_string_literal: true

# The taxpayer interview for a Colorado individual income tax return.
#
# Each task is a section of the checklist; each question page asks one thing.
# Pages with an `if:` only appear when the earlier answers make them relevant,
# so taxpayers never see questions that don't apply to them.
class TaxReturnFlow
  include Strata::Flows::ApplicationFormFlow

  task :about_you do
    question_page :filer_name
    question_page :filer_identity, fields: [ :filer_date_of_birth, :filer_ssn ]
    question_page :contact, fields: [ :mailing_address, :phone ]
    question_page :residency, fields: [ :full_year_resident ]
  end

  task :family, depends_on: [ :about_you ] do
    question_page :marital_status
    question_page :filing_jointly, if: ->(tax_return) { tax_return.married? }
    question_page :spouse, fields: [ :spouse_name, :spouse_date_of_birth, :spouse_ssn ],
      if: ->(tax_return) { tax_return.joint? }
    # Custom page: lists dependents and links to add, change or remove them.
    question_page :dependents, fields: [ :has_dependents ]
    question_page :home_costs, fields: [ :paid_over_half_home_costs ],
      if: ->(tax_return) { tax_return.ask_home_costs? }
    question_page :childcare, fields: [ :paid_childcare, :childcare_expenses ],
      if: ->(tax_return) { tax_return.ask_childcare? }
  end

  task :income, depends_on: [ :about_you, :family ] do
    # Custom page: income forms already on file with the Department, which the
    # taxpayer confirms or corrects, plus any they add.
    question_page :income_documents, fields: [ :income_documents_reviewed ]
    question_page :interest, fields: [ :has_interest_income, :taxable_interest ]
    question_page :other_income, fields: [ :has_other_income ]
  end

  task :refund, depends_on: [ :income ] do
    question_page :refund_method, fields: [ :refund_method, :bank_account_type, :bank_routing_number, :bank_account_number ]
  end

  end_page :review
end
