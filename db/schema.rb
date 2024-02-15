# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_02_15_081337) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "bonus_leave_time_logs", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "manager_id"
    t.datetime "authorize_date"
    t.integer "hours", default: 0
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crono_jobs", id: :serial, force: :cascade do |t|
    t.string "job_id", null: false
    t.text "log"
    t.datetime "last_performed_at"
    t.boolean "healthy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_crono_jobs_on_job_id", unique: true
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "leave_applications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "leave_type"
    t.integer "hours", default: 0
    t.datetime "start_time"
    t.datetime "end_time"
    t.text "description"
    t.string "status", default: "pending"
    t.datetime "sign_date"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "manager_id"
    t.text "comment"
    t.integer "leave_time_id"
    t.string "attachment"
    t.index ["manager_id"], name: "index_leave_applications_on_manager_id"
  end

  create_table "leave_hours_by_dates", id: :serial, force: :cascade do |t|
    t.integer "leave_application_id"
    t.date "date"
    t.integer "hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leave_application_id"], name: "index_leave_hours_by_dates_on_leave_application_id"
  end

  create_table "leave_time_usages", id: :serial, force: :cascade do |t|
    t.integer "leave_application_id"
    t.integer "leave_time_id"
    t.integer "used_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.index ["leave_application_id"], name: "index_leave_time_usages_on_leave_application_id"
    t.index ["leave_time_id"], name: "index_leave_time_usages_on_leave_time_id"
  end

  create_table "leave_times", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "leave_type"
    t.integer "quota"
    t.integer "usable_hours"
    t.integer "used_hours", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "refilled", default: false
    t.date "effective_date", default: -> { "now()" }, null: false
    t.date "expiration_date", default: -> { "now()" }, null: false
    t.text "remark"
    t.integer "locked_hours"
  end

  create_table "overtime_pays", id: :serial, force: :cascade do |t|
    t.integer "overtime_id"
    t.integer "user_id"
    t.integer "hour", null: false
    t.text "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["overtime_id"], name: "index_overtime_pays_on_overtime_id"
    t.index ["user_id"], name: "index_overtime_pays_on_user_id"
  end

  create_table "overtimes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "hours", default: 0
    t.datetime "start_time"
    t.datetime "end_time"
    t.text "description"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "manager_id"
    t.datetime "sign_date"
    t.datetime "deleted_at"
    t.text "comment"
    t.integer "compensatory_type", default: 0
    t.index ["compensatory_type"], name: "index_overtimes_on_compensatory_type"
    t.index ["manager_id"], name: "index_overtimes_on_manager_id"
    t.index ["user_id"], name: "index_overtimes_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "login_name", null: false
    t.string "role", default: "pending"
    t.date "join_date"
    t.date "leave_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "leave_hours_by_dates", "leave_applications"
  add_foreign_key "leave_time_usages", "leave_applications"
  add_foreign_key "leave_time_usages", "leave_times"
  add_foreign_key "overtime_pays", "overtimes"
  add_foreign_key "overtime_pays", "users"
end
