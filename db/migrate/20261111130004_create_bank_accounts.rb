class CreateBankAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :bank_code, null: false
      t.string :account_name, null: false
      t.string :account_number, null: false # encrypted
      t.string :branch
      t.datetime :verified_at
      t.timestamps
    end
  end
end
