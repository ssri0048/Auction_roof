class AddDocumentDetailsToUserProfiles < ActiveRecord::Migration[8.1]
  def change
    change_table :user_profiles, bulk: true do |t|
      t.date :company_affidavit_issued_on
      t.boolean :account_user_is_authorized_person, null: false, default: true
    end
  end
end
