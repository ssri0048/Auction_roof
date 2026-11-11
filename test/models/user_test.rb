require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "starts onboarding in progress with no steps done" do
    user = User.new

    assert user.onboarding_in_progress?
    assert_equal 0, user.onboarding_step
    assert_nil user.bidder_type
  end

  test "rejects unknown bidder types and statuses" do
    user = users(:one)

    user.bidder_type = "robot"
    user.onboarding_status = "maybe"
    assert_not user.valid?
    assert user.errors.key?(:bidder_type)
    assert user.errors.key?(:onboarding_status)
  end

  test "only bidders need onboarding" do
    assert_not users(:one).onboarding_required?, "admin is staff"
    assert users(:two).onboarding_required?, "buyer can bid"
    assert User.new.onboarding_required?, "no role yet"
  end

  test "tracks reachable and completed onboarding steps" do
    user = users(:two)
    assert_equal "profile", user.current_onboarding_step
    assert user.onboarding_step_reachable?("profile")
    assert_not user.onboarding_step_reachable?("finance")

    user.complete_onboarding_step!("profile")
    user.complete_onboarding_step!("profile")
    assert_equal 1, user.reload.onboarding_step
    assert_equal "finance", user.current_onboarding_step
  end
end
