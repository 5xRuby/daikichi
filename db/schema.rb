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

ActiveRecord::Schema.define(version: 20161006090359) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bonus_leave_time_logs", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "manager_id"
    t.datetime "authorize_date"
    t.integer  "hours",          default: 0
    t.text     "description"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "leave_application_logs", force: :cascade do |t|
    t.string   "leave_application_uuid"
    t.integer  "general_hours",          default: 0
    t.integer  "annual_hours",           default: 0
    t.boolean  "returning?",             default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.index ["leave_application_uuid"], name: "index_leave_application_logs_on_leave_application_uuid", using: :btree
  end

  create_table "leave_applications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "leave_type"
    t.integer  "hours",       default: 0
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "description"
    t.string   "status",      default: "pending"
    t.datetime "sign_date"
    t.datetime "deleted_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "manager_id"
    t.text     "comment"
    t.string   "uuid",                            null: false
    t.index ["manager_id"], name: "index_leave_applications_on_manager_id", using: :btree
    t.index ["uuid"], name: "index_leave_applications_on_uuid", unique: true, using: :btree
  end

  create_table "leave_times", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "year"
    t.string   "leave_type"
    t.integer  "quota",        default: 0
    t.integer  "usable_hours", default: 0
    t.integer  "used_hours",   default: 0
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["year"], name: "index_leave_times_on_year", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                   default: "",        null: false
    t.string   "login_name",                                 null: false
    t.string   "role",                   default: "pending"
    t.date     "join_date"
    t.date     "leave_date"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "email",                  default: "",        null: false
    t.string   "encrypted_password",     default: "",        null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,         null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
