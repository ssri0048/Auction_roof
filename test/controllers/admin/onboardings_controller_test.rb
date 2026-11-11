require "test_helper"

class Admin::OnboardingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @applicant = users(:applicant)
    complete_onboarding_steps(@applicant)
    @applicant.update!(onboarding_status: :submitted, submitted_at: 1.hour.ago)
    sign_in_as users(:one)
    Sms::Mock.clear
  end

  test "lists submitted users with warnings" do
    @applicant.profile.update!(is_pep: true)

    get admin_onboardings_path

    assert_response :success
    assert_select "td strong", "Applicant User"
    assert_select ".check-badge--warn", /PEP/
  end

  test "shows the data, documents and automatic checks" do
    get admin_onboarding_path(@applicant)

    assert_response :success
    assert_select ".check-badge--ok", /checksum/
    assert_select ".review-docs figure", 3 # ID card, selfie, book bank
    assert_select "input[name='review[bid_limit]'][value=?]", "200000"
  end

  test "approve sets the bid limit and notifies the user" do
    post review_admin_onboarding_path(@applicant), params: { review: { action: "approve", bid_limit: "150000" } }

    assert_redirected_to admin_onboardings_path
    @applicant.reload
    assert @applicant.onboarding_approved?
    assert @applicant.approved_bidder?
    assert_equal 150000, @applicant.bid_limit
    assert_equal users(:one), @applicant.approved_by
    assert_match "ผ่านการยืนยันตัวตนแล้ว", Sms::Mock.last_message.body
  end

  test "request changes reopens only the flagged steps" do
    post review_admin_onboarding_path(@applicant), params: { review: {
      action: "request_changes", steps_flagged: [ "", "documents", "bank" ], comment: "รูปบัตรไม่ชัด"
    } }

    @applicant.reload
    assert @applicant.onboarding_needs_changes?
    assert_equal %w[ documents bank ], @applicant.onboarding_flagged_steps
    assert_match "รูปบัตรไม่ชัด", Sms::Mock.last_message.body

    sign_in_as @applicant
    get onboarding_path
    assert_redirected_to onboarding_step_path("documents")
    get onboarding_step_path("profile")
    assert_redirected_to onboarding_step_path("documents")

    patch onboarding_step_path("documents"), params: { onboarding: { id_card_front: "" } }
    assert_redirected_to onboarding_step_path("bank")

    patch onboarding_step_path("bank"), params: { onboarding: { bank_code: "SCB", account_name: "Applicant User", account_number: "9876543210" } }
    assert_redirected_to onboarding_step_path("review")

    patch onboarding_step_path("review")
    assert @applicant.reload.onboarding_submitted?
  end

  test "reject and request changes need a reason" do
    post review_admin_onboarding_path(@applicant), params: { review: { action: "reject", comment: "" } }

    assert_redirected_to admin_onboarding_path(@applicant)
    assert_match "ต้องระบุเหตุผล", flash[:alert]
    assert @applicant.reload.onboarding_submitted?

    post review_admin_onboarding_path(@applicant), params: { review: { action: "reject", comment: "เอกสารปลอม" } }
    assert @applicant.reload.onboarding_rejected?
    assert_equal "เอกสารปลอม", @applicant.onboarding_reviews.sole.comment
  end

  test "only users with manage_users can review" do
    sign_in_as users(:two)
    get admin_onboardings_path
    assert_redirected_to root_path
  end
end
