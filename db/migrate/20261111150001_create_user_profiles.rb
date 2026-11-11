class CreateUserProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Step 1: individual (Thai first/last name stay on users)
      t.string :title
      t.string :first_name_en
      t.string :last_name_en
      t.string :nationality, null: false, default: "TH"
      t.string :national_id # encrypted, deterministic
      t.string :passport_no # encrypted
      t.date :date_of_birth
      t.string :gender
      t.string :line_id

      # Step 1: juristic person
      t.string :company_name_th
      t.string :company_name_en
      t.string :tax_id # encrypted, deterministic
      t.string :company_type
      t.date :company_registered_on
      t.boolean :vat_registered, null: false, default: false
      t.string :vat_branch_code
      t.string :authorized_person_name
      t.string :authorized_person_national_id # encrypted
      t.string :authorized_person_position
      t.string :contact_person_name
      t.string :contact_person_phone
      t.string :contact_person_email

      # Step 2: occupation & finance
      t.string :occupation
      t.string :occupation_other
      t.string :employer
      t.string :position
      t.string :industry
      t.string :income_range
      t.string :revenue_range
      t.string :source_of_funds, array: true, null: false, default: []
      t.string :purpose
      t.string :budget_range
      t.boolean :is_pep
      t.boolean :has_auction_experience
      t.string :auction_experience_note

      t.timestamps
    end
    add_index :user_profiles, :national_id, unique: true
    add_index :user_profiles, :tax_id, unique: true
  end
end
