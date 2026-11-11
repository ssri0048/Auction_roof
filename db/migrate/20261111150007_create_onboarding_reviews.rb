class CreateOnboardingReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :onboarding_reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :steps_flagged, array: true, null: false, default: []
      t.text :comment
      t.timestamps
    end
  end
end
