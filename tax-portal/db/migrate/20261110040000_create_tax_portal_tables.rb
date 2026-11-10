# frozen_string_literal: true

class CreateTaxPortalTables < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :full_name, :string
    add_index :users, :role

    # A taxpayer's Colorado individual income tax return (form DR 0104).
    create_table :tax_returns, id: :uuid do |t|
      # Strata::ApplicationForm base attributes
      t.uuid :user_id, null: false, index: true
      t.integer :status, null: false, default: 0
      t.datetime :submitted_at

      t.integer :tax_year, null: false
      t.string :confirmation_number, index: { unique: true }

      # About you
      t.string :filer_name_first
      t.string :filer_name_middle
      t.string :filer_name_last
      t.date :filer_date_of_birth
      t.string :filer_ssn # encrypted
      t.string :phone
      t.string :mailing_address_street_line_1
      t.string :mailing_address_street_line_2
      t.string :mailing_address_city
      t.string :mailing_address_state
      t.string :mailing_address_zip_code
      t.boolean :full_year_resident

      # Family
      t.string :marital_status
      t.boolean :filing_jointly
      t.string :spouse_name_first
      t.string :spouse_name_middle
      t.string :spouse_name_last
      t.date :spouse_date_of_birth
      t.string :spouse_ssn # encrypted
      t.boolean :has_dependents
      t.boolean :paid_over_half_home_costs

      # Income
      t.boolean :income_documents_reviewed
      t.boolean :has_interest_income
      t.integer :taxable_interest
      t.boolean :has_other_income

      # Credits
      t.boolean :paid_childcare
      t.integer :childcare_expenses

      # Refund or payment
      t.string :refund_method
      t.string :bank_account_type
      t.string :bank_routing_number
      t.string :bank_account_number # encrypted

      # Signature
      t.boolean :declaration_accepted
      t.string :signature_name

      # Latest result from the tax engine, and the facts it was computed from
      t.jsonb :calculation
      t.string :calculation_digest
      t.datetime :calculated_at

      t.timestamps
      t.index [ :user_id, :tax_year ], unique: true
    end

    create_table :dependents, id: :uuid do |t|
      t.references :tax_return, type: :uuid, null: false, foreign_key: true
      t.string :name_first, null: false
      t.string :name_last, null: false
      t.date :date_of_birth, null: false
      t.string :relationship, null: false
      t.string :ssn # encrypted, deterministic so duplicate claims can be found
      t.boolean :lived_with_filer_over_half_year, null: false, default: true
      t.boolean :full_time_student, null: false, default: false
      t.boolean :disabled, null: false, default: false
      t.timestamps
      t.index :ssn
    end

    # Income reported to the Department by employers and payers (W-2, 1099).
    # In this prototype the records are seeded; a real system would read
    # them from withholding and information-return filings.
    create_table :wage_records, id: :uuid do |t|
      t.string :ssn, null: false, index: true # encrypted, deterministic
      t.integer :tax_year, null: false
      t.string :kind, null: false
      t.string :payer_name, null: false
      t.string :payer_account_number
      t.integer :amount, null: false, default: 0
      t.integer :colorado_withholding, null: false, default: 0
      t.timestamps
    end

    # An income form on a return: either confirmed from a wage record or
    # entered by the taxpayer.
    create_table :income_documents, id: :uuid do |t|
      t.references :tax_return, type: :uuid, null: false, foreign_key: true
      t.references :wage_record, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.string :owner, null: false, default: "filer"
      t.string :payer_name, null: false
      t.integer :amount, null: false, default: 0
      t.integer :colorado_withholding, null: false, default: 0
      t.string :source, null: false, default: "taxpayer"
      t.string :review_status, null: false, default: "unreviewed"
      t.timestamps
    end

    create_table :tax_return_cases, id: :uuid do |t|
      # Strata::Case base attributes
      t.uuid :application_form_id, null: false, index: { unique: true }
      t.integer :status, null: false, default: 0
      t.string :business_process_current_step, index: true
      t.jsonb :facts, null: false, default: {}

      t.string :outcome
      t.datetime :decided_at
      t.timestamps
    end

    # A reason a return was routed to an examiner.
    create_table :review_flags, id: :uuid do |t|
      t.references :tax_return_case, type: :uuid, null: false, foreign_key: true
      t.string :code, null: false
      t.string :severity, null: false, default: "review"
      t.jsonb :details, null: false, default: {}
      t.datetime :resolved_at
      t.uuid :resolved_by_id
      t.timestamps
    end

    # A question an examiner asks the taxpayer, and the taxpayer's answer.
    create_table :information_requests, id: :uuid do |t|
      t.references :tax_return_case, type: :uuid, null: false, foreign_key: true
      t.uuid :requested_by_id, null: false
      t.text :question, null: false
      t.text :response
      t.datetime :responded_at
      t.timestamps
    end

    # A change an examiner makes to a filed amount. The filed return is
    # never edited; adjustments are applied on top of it.
    create_table :return_adjustments, id: :uuid do |t|
      t.references :tax_return_case, type: :uuid, null: false, foreign_key: true
      t.uuid :adjusted_by_id, null: false
      t.string :field, null: false
      t.integer :filed_amount, null: false
      t.integer :adjusted_amount, null: false
      t.text :reason, null: false
      t.timestamps
    end

    create_table :case_notes, id: :uuid do |t|
      t.references :tax_return_case, type: :uuid, null: false, foreign_key: true
      t.uuid :author_id, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
