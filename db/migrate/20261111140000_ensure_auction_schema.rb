# Repairs production, where earlier auction migrations were recorded in schema_migrations
# without their tables/columns being created. Creates only what is missing, so on a
# healthy database this is a no-op.
class EnsureAuctionSchema < ActiveRecord::Migration[8.1]
  TABLES = {
    auctions: {
      seller_id: [ :bigint, null: false ],
      title: [ :string, null: false ],
      description: [ :text ],
      starting_price: [ :decimal, precision: 14, scale: 2, null: false ],
      min_increment: [ :decimal, precision: 14, scale: 2 ],
      current_price: [ :decimal, precision: 14, scale: 2 ],
      bids_count: [ :integer, default: 0, null: false ],
      starts_at: [ :datetime, null: false ],
      ends_at: [ :datetime, null: false ],
      status: [ :string, default: "draft", null: false ],
      winner_id: [ :bigint ],
      closed_at: [ :datetime ],
      ending_soon_notified_at: [ :datetime ],
      auction_type: [ :string, default: "english", null: false ],
      approved_by_id: [ :bigint ],
      approved_at: [ :datetime ],
      rejection_reason: [ :string ],
      created_at: [ :datetime, null: false ],
      updated_at: [ :datetime, null: false ]
    },
    bids: {
      auction_id: [ :bigint, null: false ],
      user_id: [ :bigint, null: false ],
      amount: [ :decimal, precision: 14, scale: 2, null: false ],
      created_at: [ :datetime, null: false ],
      updated_at: [ :datetime, null: false ]
    },
    chat_messages: {
      auction_id: [ :bigint, null: false ],
      user_id: [ :bigint, null: false ],
      body: [ :string, null: false ],
      created_at: [ :datetime, null: false ],
      updated_at: [ :datetime, null: false ]
    },
    notifications: {
      user_id: [ :bigint, null: false ],
      auction_id: [ :bigint ],
      kind: [ :string, null: false ],
      message: [ :string, null: false ],
      read_at: [ :datetime ],
      created_at: [ :datetime, null: false ],
      updated_at: [ :datetime, null: false ]
    }
  }.freeze

  INDEXES = {
    auctions: [ [ :approved_by_id ], [ :seller_id ], [ :starts_at ], [ :status, :ends_at ], [ :winner_id ] ],
    bids: [ [ :auction_id, :amount ], [ :auction_id ], [ :user_id ] ],
    chat_messages: [ [ :auction_id ], [ :user_id ] ],
    notifications: [ [ :auction_id ], [ :user_id, :read_at ], [ :user_id ] ]
  }.freeze

  FOREIGN_KEYS = [
    [ :auctions, :users, :approved_by_id ], [ :auctions, :users, :seller_id ], [ :auctions, :users, :winner_id ],
    [ :bids, :auctions, :auction_id ], [ :bids, :users, :user_id ],
    [ :chat_messages, :auctions, :auction_id ], [ :chat_messages, :users, :user_id ],
    [ :notifications, :auctions, :auction_id ], [ :notifications, :users, :user_id ]
  ].freeze

  def up
    TABLES.each do |table, columns|
      create_table(table) unless table_exists?(table)

      columns.each do |name, (type, options)|
        options ||= {}
        next if column_exists?(table, name)
        # Add as nullable first; only enforce NOT NULL if no existing row would break it.
        add_column table, name, type, **options.except(:null)
        if options[:null] == false && !select_value("SELECT 1 FROM #{quote_table_name(table)} WHERE #{quote_column_name(name)} IS NULL LIMIT 1")
          change_column_null table, name, false
        end
      end
    end

    change_column_null :auctions, :min_increment, true

    INDEXES.each do |table, indexes|
      indexes.each { |cols| add_index table, cols, if_not_exists: true }
    end

    FOREIGN_KEYS.each do |from, to, column|
      add_foreign_key from, to, column: column, if_not_exists: true
    end
  end

  def down
    # Nothing to undo: earlier migrations own these tables.
  end
end
