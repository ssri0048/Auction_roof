module OnboardingHelper
  def onboarding_step_label(step)
    OnboardingOptions::STEP_LABELS.fetch(step)
  end

  # Error messages for the step's records. Errors that autosave copies onto the parent
  # ("profile.national_id") are skipped, since the nested record reports them itself.
  def onboarding_error_messages(*records)
    records.compact.flat_map { |record| record.errors.reject { it.attribute.to_s.include?(".") }.map(&:full_message) }
  end
end
