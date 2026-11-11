# Step 8: checks every step again and submits the user for admin review.
class Onboarding::Submission
  include ActiveModel::Model

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def submit
    return false unless valid?

    user.update!(onboarding_status: :submitted, submitted_at: Time.current, onboarding_step: User::ONBOARDING_STEPS.length)
    Onboarding::Notifier.notify(user, :submitted)
    true
  end

  def valid?
    errors.clear
    incomplete_steps.each { errors.add(:base, "ขั้นตอน \"#{OnboardingOptions::STEP_LABELS[it]}\" ยังไม่ครบ กรุณากด แก้ไข") }
    errors.empty?
  end

  def incomplete_steps
    profile = user.profile
    bank_account = user.bank_accounts.first
    {
      "profile" => profile && user.valid?(:profile_step),
      "finance" => profile&.valid?(:finance_step),
      "address" => user.addresses.registered.exists?,
      "documents" => profile&.valid?(:documents_step),
      "bank" => bank_account&.valid?(:bank_step),
      "consents" => Consent::REQUIRED_KINDS.all? { |kind| user.consents.active.any? { it.kind == kind && it.current? } }
    }.reject { |_, complete| complete }.keys
  end
end
