class AddOnboardingToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :bidder_type
      t.string :onboarding_status, null: false, default: "in_progress"
      t.integer :onboarding_step, null: false, default: 0
      t.datetime :submitted_at
      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :users }
      t.decimal :bid_limit, precision: 15, scale: 2
    end
    add_index :users, :onboarding_status
  end
end
