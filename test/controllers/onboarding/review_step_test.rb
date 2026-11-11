require "test_helper"

class Onboarding::ReviewStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    complete_onboarding_steps(@user)
    sign_in_as @user
    Sms::Mock.clear
  end

  test "summarises every step with edit links and masked numbers" do
    get onboarding_step_path("review")

    assert_response :success
    assert_select ".summary__section", 7
    assert_select ".summary__section a[href=?]", onboarding_step_path("bank"), "แก้ไข"
    assert_select "dd", /x-xxxx-xxxxx-45-0/
    assert_select "dd", /xxxxxx7890/
    assert_no_match VALID_NATIONAL_ID, response.body
  end

  test "submit sends the user for review and notifies them" do
    patch onboarding_step_path("review")

    assert_redirected_to root_path
    @user.reload
    assert @user.onboarding_submitted?
    assert @user.submitted_at
    assert_equal "onboarding", @user.notifications.last.kind
    assert_equal @user.phone, Sms::Mock.last_message.to
    assert_match "ได้รับข้อมูลยืนยันตัวตนแล้ว", Sms::Mock.last_message.body
  end

  test "submit re-checks every step" do
    @user.bank_accounts.destroy_all
    @user.consents.terms.update_all(document_version: "old")

    patch onboarding_step_path("review")

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /"บัญชีรับเงินคืน" ยังไม่ครบ/
    assert_select ".flash--alert li", /"ข้อตกลงและความยินยอม" ยังไม่ครบ/
    assert @user.reload.onboarding_in_progress?
  end
end
