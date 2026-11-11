class CreateThaiGeography < ActiveRecord::Migration[8.1]
  def change
    create_table :provinces do |t|
      t.string :code, null: false
      t.string :name_th, null: false
      t.string :name_en
      t.timestamps
    end
    add_index :provinces, :code, unique: true

    create_table :districts do |t|
      t.references :province, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name_th, null: false
      t.string :name_en
      t.timestamps
    end
    add_index :districts, :code, unique: true

    create_table :sub_districts do |t|
      t.references :district, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name_th, null: false
      t.string :name_en
      t.string :postcode, null: false
      t.timestamps
    end
    add_index :sub_districts, :code, unique: true
  end
end
