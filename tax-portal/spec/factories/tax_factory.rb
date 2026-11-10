# frozen_string_literal: true

FactoryBot.define do
  sequence(:ssn) { |n| format("000%06d", 100_000 + n) }

  factory :taxpayer, parent: :user do
    role { :taxpayer }
    full_name { "Tess Payer" }
  end

  factory :examiner, parent: :user do
    role { :examiner }
    full_name { "Exa Miner" }
  end

  factory :wage_record do
    ssn
    tax_year { TaxReturn::CURRENT_TAX_YEAR }
    kind { "w2" }
    payer_name { "Front Range Outfitters" }
    amount { 48_000 }
    colorado_withholding { 1_650 }
  end

  # A blank return, as created when the taxpayer clicks "Start my return".
  factory :tax_return do
    user factory: :taxpayer

    # Every section answered: a single filer whose one W-2 is on file and
    # confirmed. Ready to review and sign.
    trait :complete do
      filer_name_first { "Tess" }
      filer_name_last { "Payer" }
      filer_date_of_birth { Date.new(1990, 4, 1) }
      filer_ssn { generate(:ssn) }
      mailing_address_street_line_1 { "1375 Sherman St" }
      mailing_address_city { "Denver" }
      mailing_address_state { "CO" }
      mailing_address_zip_code { "80261" }
      full_year_resident { true }
      marital_status { "unmarried" }
      has_dependents { false }
      has_interest_income { false }
      has_other_income { false }
      refund_method { "check" }

      transient do
        wages { 48_000 }
        withheld { 1_650 }
      end

      after(:create) do |tax_return, evaluator|
        create(:wage_record, ssn: tax_return.filer_ssn, amount: evaluator.wages, colorado_withholding: evaluator.withheld)
        RecordsOnFile.prefill(tax_return).each(&:confirm!)
        tax_return.update!(income_documents_reviewed: true)
      end
    end

    trait :submitted do
      complete

      after(:create) do |tax_return|
        tax_return.assign_attributes(declaration_accepted: true, signature_name: tax_return.filer_full_name)
        tax_return.submit_application || raise(tax_return.errors.full_messages.to_sentence)
      end
    end

    # Submitted with more withholding than the employer reported, so the
    # automatic checks send it to an examiner.
    trait :flagged do
      complete

      after(:create) do |tax_return|
        tax_return.income_documents.first.correct!(colorado_withholding: 2_650)
        tax_return.assign_attributes(declaration_accepted: true, signature_name: tax_return.filer_full_name)
        tax_return.submit_application || raise(tax_return.errors.full_messages.to_sentence)
      end
    end
  end

  factory :dependent do
    tax_return
    name_first { "Kid" }
    name_last { "Payer" }
    date_of_birth { Date.new(2019, 6, 1) }
    relationship { "child" }
    ssn
  end
end
