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
end
