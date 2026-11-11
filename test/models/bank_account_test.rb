require "test_helper"

class BankAccountTest < ActiveSupport::TestCase
  test "encrypts and masks the account number" do
    account = users(:one).bank_accounts.create!(bank_code: "KBANK", account_name: " One  User ", account_number: "123-4-56789-0")
    raw = BankAccount.connection.select_value("SELECT account_number FROM bank_accounts WHERE id = #{account.id}")

    assert_not_includes raw, "1234567890"
    assert_equal "1234567890", account.reload.account_number
    assert_equal "xxxxxx7890", account.masked_account_number
    assert_equal "One User", account.account_name
  end
end
