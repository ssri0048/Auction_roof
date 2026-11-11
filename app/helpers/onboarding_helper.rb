module OnboardingHelper
  ONBOARDING_STEP_LABELS = {
    "profile" => "ข้อมูลส่วนตัว",
    "finance" => "อาชีพและรายได้",
    "address" => "ที่อยู่",
    "documents" => "เอกสารยืนยันตัวตน",
    "bank" => "บัญชีรับเงินคืน",
    "interests" => "ความสนใจ",
    "consents" => "ข้อตกลงและความยินยอม",
    "review" => "ตรวจสอบและยืนยัน"
  }.freeze

  def onboarding_step_label(step)
    ONBOARDING_STEP_LABELS.fetch(step)
  end

  # Error messages for the step's records. Errors that autosave copies onto the parent
  # ("profile.national_id") are skipped, since the nested record reports them itself.
  def onboarding_error_messages(*records)
    records.compact.flat_map { |record| record.errors.reject { it.attribute.to_s.include?(".") }.map(&:full_message) }
  end
end
