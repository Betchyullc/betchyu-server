# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140627172255) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bets", force: true do |t|
    t.string   "noun"
    t.string   "verb"
    t.string   "owner"
    t.integer  "stakeAmount"
    t.string   "stakeType"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "amount"
    t.string   "status"
    t.decimal  "initial"
    t.integer  "duration"
  end

  create_table "invites", force: true do |t|
    t.string   "status"
    t.string   "invitee"
    t.string   "inviter"
    t.integer  "bet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invites", ["bet_id"], name: "index_invites_on_bet_id", using: :btree

  create_table "notifications", force: true do |t|
    t.string   "user"
    t.integer  "kind"
    t.string   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: true do |t|
    t.string   "braintree_id"
    t.integer  "bet_id"
    t.string   "user"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "submitted"
  end

  add_index "transactions", ["bet_id"], name: "index_transactions_on_bet_id", using: :btree

  create_table "updates", force: true do |t|
    t.integer  "value"
    t.integer  "bet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "updates", ["bet_id"], name: "index_updates_on_bet_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "fb_id"
    t.string   "device"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_hash"
  end

end
