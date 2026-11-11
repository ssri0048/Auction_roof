require "test_helper"

class Onboarding::InterestsAndConsentsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:applicant)
    complete_profile_step(@user)
    complete_finance_step(@user)
    complete_address_step(@user)
    complete_documents_step(@user)
    complete_bank_step(@user)
    @user.update!(onboarding_step: 5) # back on "interests"
    sign_in_as @user
  end

  test "interests can be skipped" do
    patch onboarding_step_path("interests"), params: { skip: "1" }

    assert_redirected_to onboarding_step_path("consents")
    assert_nil @user.reload.interest
  end

  test "saves interests" do
    patch onboarding_step_path("interests"), params: { onboarding: {
      categories: [ "", "transformers", "cables_scrap" ], province_codes: [ "", "10" ], notify_channels: [ "sms" ], notify_events: [ "outbid" ]
    } }

    assert_redirected_to onboarding_step_path("consents")
    assert_equal %w[ transformers cables_scrap ], @user.reload.interest.categories
    assert_equal %w[ 10 ], @user.interest.province_codes
  end

  test "consents start unticked and the required ones must be accepted" do
    @user.complete_onboarding_step!("interests")
    get onboarding_step_path("consents")
    assert_select ".consent input[type=checkbox][checked]", false

    patch onboarding_step_path("consents"), params: { onboarding: { terms: "1", marketing: "1" } }

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /ต้องยอมรับ "กติกาการประมูล"/
    assert_empty @user.consents
  end

  test "records the version, time and IP, and revokes an unticked optional consent" do
    @user.complete_onboarding_step!("interests")
    accept_all = Consent::DOCUMENTS.keys.index_with { "1" }

    patch onboarding_step_path("consents"), params: { onboarding: accept_all }

    assert_redirected_to onboarding_step_path("review")
    terms = @user.consents.terms.sole
    assert_equal Consent.current_version(:terms), terms.document_version
    assert_equal "127.0.0.1", terms.ip_address

    patch onboarding_step_path("consents"), params: { onboarding: accept_all.merge("marketing" => "0") }

    assert_equal 1, @user.consents.terms.count, "unchanged consents aren't recorded again"
    assert_not_nil @user.consents.marketing.sole.revoked_at
  end
end
