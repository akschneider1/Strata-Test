# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_11_10_050000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "case_notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tax_return_case_id", null: false
    t.uuid "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_return_case_id"], name: "index_case_notes_on_tax_return_case_id"
  end

  create_table "dependents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tax_return_id", null: false
    t.string "name_first", null: false
    t.string "name_last", null: false
    t.date "date_of_birth", null: false
    t.string "relationship", null: false
    t.string "ssn"
    t.boolean "lived_with_filer_over_half_year", default: true, null: false
    t.boolean "full_time_student", default: false, null: false
    t.boolean "disabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "income_under_limit"
    t.boolean "supported_by_filer"
    t.index ["ssn"], name: "index_dependents_on_ssn"
    t.index ["tax_return_id"], name: "index_dependents_on_tax_return_id"
  end

  create_table "income_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tax_return_id", null: false
    t.uuid "wage_record_id"
    t.string "kind", null: false
    t.string "owner", default: "filer", null: false
    t.string "payer_name", null: false
    t.integer "amount", default: 0, null: false
    t.integer "colorado_withholding", default: 0, null: false
    t.string "source", default: "taxpayer", null: false
    t.string "review_status", default: "unreviewed", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_return_id"], name: "index_income_documents_on_tax_return_id"
    t.index ["wage_record_id"], name: "index_income_documents_on_wage_record_id"
  end

  create_table "information_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tax_return_case_id", null: false
    t.uuid "requested_by_id", null: false
    t.text "question", null: false
    t.text "response"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_return_case_id"], name: "index_information_requests_on_tax_return_case_id"
  end

  create_table "return_adjustments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tax_return_case_id", null: false
    t.uuid "adjusted_by_id", null: false
    t.string "field", null: false
    t.integer "filed_amount", null: false
    t.integer "adjusted_amount", null: false
    t.text "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_return_case_id"], name: "index_return_adjustments_on_tax_return_case_id"
  end

  create_table "review_flags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "tax_return_case_id", null: false
    t.string "code", null: false
    t.string "severity", default: "review", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "resolved_at"
    t.uuid "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_return_case_id"], name: "index_review_flags_on_tax_return_case_id"
  end

  create_table "strata_audit_lines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.uuid "subject_id"
    t.string "subject_type"
    t.uuid "actor_id"
    t.string "actor_type"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_strata_audit_lines_on_polymorphic_actor"
    t.index ["created_at"], name: "index_strata_audit_lines_on_created_at"
    t.index ["subject_type", "subject_id", "created_at"], name: "index_strata_audit_lines_on_subject_and_created_at", order: { created_at: :desc }
  end

  create_table "strata_event_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "subscriber", null: false
    t.integer "status", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "next_attempt_at"
    t.datetime "enqueued_at"
    t.string "error_class"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "subscriber"], name: "index_strata_event_deliveries_on_event_id_and_subscriber", unique: true
    t.index ["next_attempt_at"], name: "index_strata_event_deliveries_on_sweep", where: "((status = ANY (ARRAY[0, 2])) AND (enqueued_at IS NULL))"
  end

  create_table "strata_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "publisher_type"
    t.uuid "publisher_id"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_strata_events_on_created_at"
    t.index ["name", "created_at"], name: "index_strata_events_on_name_and_created_at"
    t.index ["publisher_type", "publisher_id"], name: "index_strata_events_on_publisher"
  end

  create_table "strata_tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.text "description"
    t.integer "status", default: 0
    t.uuid "assignee_id"
    t.uuid "case_id"
    t.string "case_type"
    t.date "due_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_strata_tasks_on_assignee_id"
    t.index ["case_id"], name: "index_strata_tasks_on_case_id"
    t.index ["status"], name: "index_strata_tasks_on_status"
    t.index ["type"], name: "index_strata_tasks_on_type"
  end

  create_table "tax_return_cases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_form_id", null: false
    t.integer "status", default: 0, null: false
    t.string "business_process_current_step"
    t.jsonb "facts", default: {}, null: false
    t.string "outcome"
    t.datetime "decided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_form_id"], name: "index_tax_return_cases_on_application_form_id", unique: true
    t.index ["business_process_current_step"], name: "index_tax_return_cases_on_business_process_current_step"
  end

  create_table "tax_returns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.integer "tax_year", null: false
    t.string "confirmation_number"
    t.string "filer_name_first"
    t.string "filer_name_middle"
    t.string "filer_name_last"
    t.date "filer_date_of_birth"
    t.string "filer_ssn"
    t.string "phone"
    t.string "mailing_address_street_line_1"
    t.string "mailing_address_street_line_2"
    t.string "mailing_address_city"
    t.string "mailing_address_state"
    t.string "mailing_address_zip_code"
    t.boolean "full_year_resident"
    t.string "marital_status"
    t.boolean "filing_jointly"
    t.string "spouse_name_first"
    t.string "spouse_name_middle"
    t.string "spouse_name_last"
    t.date "spouse_date_of_birth"
    t.string "spouse_ssn"
    t.boolean "has_dependents"
    t.boolean "paid_over_half_home_costs"
    t.boolean "income_documents_reviewed"
    t.boolean "has_interest_income"
    t.integer "taxable_interest"
    t.boolean "has_other_income"
    t.boolean "paid_childcare"
    t.integer "childcare_expenses"
    t.string "refund_method"
    t.string "bank_account_type"
    t.string "bank_routing_number"
    t.string "bank_account_number"
    t.boolean "declaration_accepted"
    t.string "signature_name"
    t.jsonb "calculation"
    t.string "calculation_digest"
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_number"], name: "index_tax_returns_on_confirmation_number", unique: true
    t.index ["user_id", "tax_year"], name: "index_tax_returns_on_user_id_and_tax_year", unique: true
    t.index ["user_id"], name: "index_tax_returns_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "uid", null: false
    t.string "provider", null: false
    t.string "email", default: "", null: false
    t.integer "mfa_preference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "full_name"
    t.index ["role"], name: "index_users_on_role"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "wage_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ssn", null: false
    t.integer "tax_year", null: false
    t.string "kind", null: false
    t.string "payer_name", null: false
    t.string "payer_account_number"
    t.integer "amount", default: 0, null: false
    t.integer "colorado_withholding", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ssn"], name: "index_wage_records_on_ssn"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "case_notes", "tax_return_cases"
  add_foreign_key "dependents", "tax_returns"
  add_foreign_key "income_documents", "tax_returns"
  add_foreign_key "income_documents", "wage_records"
  add_foreign_key "information_requests", "tax_return_cases"
  add_foreign_key "return_adjustments", "tax_return_cases"
  add_foreign_key "review_flags", "tax_return_cases"
  add_foreign_key "strata_event_deliveries", "strata_events", column: "event_id", on_delete: :cascade
end
