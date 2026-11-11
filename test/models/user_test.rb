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
end
