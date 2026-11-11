class AddBidLimitToOnboardingReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :onboarding_reviews, :bid_limit, :decimal, precision: 15, scale: 2
  end
end
