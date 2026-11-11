# Account used to refund deposits to unsuccessful bidders (Step 5).
class BankAccount < ApplicationRecord
  belongs_to :user

  encrypts :account_number
  has_one_attached :book_bank

  normalizes :account_number, with: ->(n) { n.gsub(/\D/, "") }
  normalizes :account_name, with: ->(n) { n.squish }

  # Shows only the last 4 digits: "xxxxxx1234".
  def masked_account_number
    return if account_number.blank?

    "#{"x" * [ account_number.length - 4, 0 ].max}#{account_number.last(4)}"
  end
end
