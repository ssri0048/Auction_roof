require "test_helper"

class Onboarding::FinanceStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    complete_profile_step(@user)
    sign_in_as @user
  end

  def finance_params(**overrides)
    { onboarding: { occupation: "employee", employer: "บริษัท เอ", industry: "recycling", income_range: "30k_50k",
                    source_of_funds: [ "", "salary", "savings" ], purpose: "resale", budget_range: "50k_200k",
                    is_pep: "false", **overrides } }
  end

  test "shows income for individuals" do
    get onboarding_step_path("finance")

    assert_response :success
    assert_select "select[name='onboarding[income_range]']"
    assert_select "select[name='onboarding[revenue_range]']", false
  end

  test "saves the step" do
    patch onboarding_step_path("finance"), params: finance_params

    assert_redirected_to onboarding_step_path("address")
    profile = @user.reload.profile
    assert_equal %w[ salary savings ], profile.source_of_funds
    assert_equal false, profile.is_pep
  end

  test "requires the PEP answer, sources of funds and an employer" do
    patch onboarding_step_path("finance"), params: finance_params(is_pep: "", source_of_funds: [ "" ], employer: "")

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /PEP\) กรุณาตอบ/
    assert_select ".flash--alert li", /แหล่งที่มาของเงิน เลือกอย่างน้อย 1 ข้อ/
    assert_select ".flash--alert li", /ชื่อนายจ้าง/
  end

  test "students don't need an employer" do
    patch onboarding_step_path("finance"), params: finance_params(occupation: "student", employer: "")
    assert_redirected_to onboarding_step_path("address")
  end

  test "juristic bidders give annual revenue instead of occupation" do
    @user.update!(bidder_type: "juristic")
    patch onboarding_step_path("finance"), params: { onboarding: {
      industry: "recycling", revenue_range: "10m_50m", source_of_funds: [ "business_income" ],
      purpose: "recycling", budget_range: "1m_5m", is_pep: "false"
    } }

    assert_redirected_to onboarding_step_path("address")
    assert_equal "10m_50m", @user.reload.profile.revenue_range
  end
end
