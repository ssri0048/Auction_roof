require "test_helper"

class OnboardingReviewTest < ActiveSupport::TestCase
  test "only accepts known onboarding steps" do
    review = OnboardingReview.new(user: users(:two), reviewer: users(:one), action: :request_changes, steps_flagged: %w[profile bank])
    assert review.valid?

    review.steps_flagged = %w[profile nope]
    assert_not review.valid?
  end

  test "rejects unknown actions" do
    assert_not OnboardingReview.new(user: users(:two), reviewer: users(:one), action: "delete").valid?
  end
end
