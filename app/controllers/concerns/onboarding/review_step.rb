# Step 8: read-only summary, then submit for admin review.
module Onboarding::ReviewStep
  private
    def load_review_step
      @record = Onboarding::Submission.new(Current.user)
    end

    def save_review_step
      @record.submit
    end
end
