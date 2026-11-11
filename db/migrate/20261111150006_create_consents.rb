class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :consents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :document_version, null: false
      t.datetime :accepted_at, null: false
      t.string :ip_address
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :consents, %i[ user_id kind ]
  end
end
