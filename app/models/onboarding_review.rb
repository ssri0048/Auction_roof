# Audit log of admin decisions on a user's onboarding.
class OnboardingReview < ApplicationRecord
  enum :action, { approve: "approve", request_changes: "request_changes", reject: "reject" }, prefix: true, validate: true

  belongs_to :user
  belongs_to :reviewer, class_name: "User"

  validates :comment, presence: { message: "ต้องระบุเหตุผล" }, unless: :action_approve?
  validates :steps_flagged, presence: { message: "เลือกอย่างน้อย 1 ขั้นตอน" }, if: :action_request_changes?
  validates :bid_limit, numericality: { greater_than: 0 }, allow_nil: true
  validate :steps_flagged_are_known

  private
    def steps_flagged_are_known
      unknown = steps_flagged - User::ONBOARDING_STEPS
      errors.add(:steps_flagged, "ไม่รู้จักขั้นตอน: #{unknown.join(", ")}") if unknown.any?
    end
end
