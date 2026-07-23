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

ActiveRecord::Schema[8.1].define(version: 2026_07_22_124708) do
  create_table "alerts", force: :cascade do |t|
    t.string "alert_type", null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.integer "due_odometer"
    t.integer "last_notified_stage", default: 0, null: false
    t.datetime "sent_at"
    t.integer "service_type_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "vehicle_id", null: false
    t.index ["service_type_id"], name: "index_alerts_on_service_type_id"
    t.index ["vehicle_id"], name: "index_alerts_on_vehicle_id"
  end

  create_table "bike_models", force: :cascade do |t|
    t.string "brand", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["brand", "name"], name: "index_bike_models_on_brand_and_name", unique: true
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "amount", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "invoice_id", null: false
    t.string "item_type", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "amount", null: false
    t.datetime "created_at", null: false
    t.string "file_url"
    t.string "invoice_number"
    t.date "issued_at"
    t.integer "service_record_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by", null: false
    t.integer "vehicle_id", null: false
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["service_record_id"], name: "index_invoices_on_service_record_id"
    t.index ["uploaded_by"], name: "index_invoices_on_uploaded_by"
    t.index ["vehicle_id"], name: "index_invoices_on_vehicle_id"
  end

  create_table "odometer_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "logged_by", null: false
    t.integer "reading", null: false
    t.datetime "recorded_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", null: false
    t.integer "vehicle_id", null: false
    t.index ["logged_by"], name: "index_odometer_logs_on_logged_by"
    t.index ["vehicle_id"], name: "index_odometer_logs_on_vehicle_id"
  end

  create_table "service_records", force: :cascade do |t|
    t.bigint "completed_by", null: false
    t.datetime "created_at", null: false
    t.date "next_due_date"
    t.integer "next_due_odometer"
    t.text "notes"
    t.integer "odometer_at_service", null: false
    t.integer "service_type_id", null: false
    t.datetime "serviced_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", null: false
    t.integer "vehicle_id", null: false
    t.index ["completed_by"], name: "index_service_records_on_completed_by"
    t.index ["service_type_id"], name: "index_service_records_on_service_type_id"
    t.index ["vehicle_id"], name: "index_service_records_on_vehicle_id"
  end

  create_table "service_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_url"
    t.integer "service_record_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at", default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "uploaded_by", null: false
    t.integer "vehicle_id", null: false
    t.index ["service_record_id"], name: "index_service_reports_on_service_record_id", unique: true
    t.index ["uploaded_by"], name: "index_service_reports_on_uploaded_by"
    t.index ["vehicle_id"], name: "index_service_reports_on_vehicle_id"
  end

  create_table "service_schedules", force: :cascade do |t|
    t.integer "bike_model_id", null: false
    t.datetime "created_at", null: false
    t.bigint "interval_km"
    t.integer "interval_months"
    t.integer "service_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["bike_model_id", "service_type_id"], name: "index_service_schedules_on_bike_model_id_and_service_type_id", unique: true
    t.index ["bike_model_id"], name: "index_service_schedules_on_bike_model_id"
    t.index ["service_type_id"], name: "index_service_schedules_on_service_type_id"
  end

  create_table "service_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_service_types_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.integer "bike_model_id", null: false
    t.datetime "created_at", null: false
    t.date "purchase_date", null: false
    t.string "registration_number", null: false
    t.datetime "updated_at", null: false
    t.index ["bike_model_id"], name: "index_vehicles_on_bike_model_id"
    t.index ["registration_number"], name: "index_vehicles_on_registration_number", unique: true
  end

  add_foreign_key "alerts", "service_types"
  add_foreign_key "alerts", "vehicles"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "service_records"
  add_foreign_key "invoices", "users", column: "uploaded_by"
  add_foreign_key "invoices", "vehicles"
  add_foreign_key "odometer_logs", "users", column: "logged_by"
  add_foreign_key "odometer_logs", "vehicles"
  add_foreign_key "service_records", "service_types"
  add_foreign_key "service_records", "users", column: "completed_by"
  add_foreign_key "service_records", "vehicles"
  add_foreign_key "service_reports", "service_records"
  add_foreign_key "service_reports", "users", column: "uploaded_by"
  add_foreign_key "service_reports", "vehicles"
  add_foreign_key "service_schedules", "bike_models"
  add_foreign_key "service_schedules", "service_types"
  add_foreign_key "vehicles", "bike_models"
end
