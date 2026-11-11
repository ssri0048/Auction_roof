class CreateUserInterests < ActiveRecord::Migration[8.1]
  def change
    create_table :user_interests do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :categories, array: true, null: false, default: []
      t.string :province_codes, array: true, null: false, default: []
      t.string :notify_channels, array: true, null: false, default: []
      t.string :notify_events, array: true, null: false, default: []
      t.timestamps
    end
  end
end
