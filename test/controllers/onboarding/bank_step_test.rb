require "test_helper"

class Onboarding::BankStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:applicant)
    complete_profile_step(@user)
    complete_finance_step(@user)
    complete_address_step(@user)
    complete_documents_step(@user)
    sign_in_as @user
  end

  def bank_params(**overrides)
    { onboarding: { bank_code: "KBANK", account_name: "นาย Applicant User", account_number: "123-4-56789-0",
                    book_bank: fixture_file_upload("id_card.png", "image/png"), **overrides } }
  end

  test "pre-fills the account name from the profile" do
    get onboarding_step_path("bank")
    assert_select "input[name='onboarding[account_name]'][value=?]", "Applicant User"
  end

  test "saves the account and recognises the bidder's own name" do
    patch onboarding_step_path("bank"), params: bank_params

    assert_redirected_to onboarding_step_path("interests")
    account = @user.bank_accounts.sole
    assert_equal "1234567890", account.account_number
    assert account.name_matches_profile?
  end

  test "flags an account in someone else's name but still saves it" do
    patch onboarding_step_path("bank"), params: bank_params(account_name: "นางสาว คนอื่น")

    assert_redirected_to onboarding_step_path("interests")
    assert_not @user.bank_accounts.sole.name_matches_profile?

    get onboarding_step_path("bank")
    assert_select ".flash--alert", /ชื่อบัญชีไม่ตรงกับชื่อในโปรไฟล์/
  end

  test "validates the account number and requires the book bank photo" do
    patch onboarding_step_path("bank"), params: bank_params(account_number: "12345", book_bank: "")

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /เลขที่บัญชี ต้องเป็นตัวเลข 10–15 หลัก/
    assert_select ".flash--alert li", /รูปหน้าสมุดบัญชี ต้องอัปโหลด/
  end
end
