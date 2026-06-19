# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email, null: false
      t.boolean :admin, null: false, default: false
      t.timestamptz :profile_completed_at

      t.timestamps null: false
    end

    # Primary find-or-create key: provider + uid uniquely identifies a user at the IdP
    add_index :users, %i[provider uid], unique: true

    # Email index for case-insensitive lookups (used in later stories)
    add_index :users, :email, unique: true
  end
end
