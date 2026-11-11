class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :house_no, null: false
      t.string :moo
      t.string :building
      t.string :soi
      t.string :road
      t.references :sub_district, null: false, foreign_key: true
      t.string :postcode, null: false
      t.timestamps
    end
    add_index :addresses, %i[ user_id kind ], unique: true
  end
end
