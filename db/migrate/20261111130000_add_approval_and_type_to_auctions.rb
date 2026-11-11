class AddApprovalAndTypeToAuctions < ActiveRecord::Migration[8.1]
  def change
    # if_not_exists keeps this safe to re-run on a database left half-migrated.
    add_column :auctions, :auction_type, :string, null: false, default: "english", if_not_exists: true
    add_reference :auctions, :approved_by, foreign_key: { to_table: :users }, if_not_exists: true
    add_column :auctions, :approved_at, :datetime, if_not_exists: true
    add_column :auctions, :rejection_reason, :string, if_not_exists: true
    # Sealed-bid auctions have no bid increment.
    change_column_null :auctions, :min_increment, true
  end
end
