# Step 6 (optional): interests and notifications. Step 7: terms and consents.
module Onboarding::InterestsStep
  private
    def load_interests_step
      # Built by user_id so a skipped step doesn't autosave an empty record with the user.
      @record = Current.user.interest || UserInterest.new(user_id: Current.user.id)
    end

    def save_interests_step
      @record.assign_attributes(params.expect(onboarding: [ categories: [], province_codes: [], notify_channels: [], notify_events: [] ]))
      @record.save(context: :interests_step)
    end

    def load_consents_step
      @record = Onboarding::ConsentForm.new(Current.user)
    end

    def save_consents_step
      @record.assign(params.expect(onboarding: Consent::DOCUMENTS.keys))
      @record.save(ip_address: request.remote_ip)
    end
end
