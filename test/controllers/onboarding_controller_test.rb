require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bidder = users(:two)
    sign_in_as @bidder
  end

  test "show sends the user to their first incomplete step" do
    @bidder.update!(onboarding_step: 2)

    get onboarding_path
    assert_redirected_to onboarding_step_path("address")
  end

  test "edit shows the progress" do
    get onboarding_step_path("profile")

    assert_response :success
    assert_select ".onboarding-progress__count", "ขั้นตอน 1 จาก 8"
  end

  test "next completes the step and moves on" do
    patch onboarding_step_path("profile"), params: { onboarding: {
      bidder_type: "individual", first_name: "Two", last_name: "User", email_address: "two@example.com",
      profile_attributes: { title: "mr", national_id: "1101700203450", date_of_birth: "1990-01-01" }
    } }

    assert_redirected_to onboarding_step_path("finance")
    assert_equal 1, @bidder.reload.onboarding_step
  end

  test "back goes to the previous step without completing this one" do
    @bidder.update!(onboarding_step: 1)

    patch onboarding_step_path("finance"), params: { back: "1" }

    assert_redirected_to onboarding_step_path("profile")
    assert_equal 1, @bidder.reload.onboarding_step
  end

  test "steps after the first incomplete one can't be opened" do
    get onboarding_step_path("bank")
    assert_redirected_to onboarding_step_path("profile")
  end

  test "staff and users who already submitted are sent home" do
    sign_in_as users(:one)
    get onboarding_path
    assert_redirected_to root_path

    sign_in_as @bidder
    @bidder.update!(onboarding_status: :submitted)
    get onboarding_step_path("profile")
    assert_redirected_to root_path
  end

  test "home shows the onboarding status until the user is approved" do
    get root_path
    assert_select ".onboarding-banner", /กรอกข้อมูลให้ครบเพื่อเริ่มประมูล/

    @bidder.update!(onboarding_status: :submitted)
    get root_path
    assert_select ".onboarding-banner", /อยู่ระหว่างตรวจสอบ/

    @bidder.update!(onboarding_status: :approved)
    get root_path
    assert_select ".onboarding-banner", false
  end
end
