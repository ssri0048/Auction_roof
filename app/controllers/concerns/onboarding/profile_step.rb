# Step 1: bidder type, account name/email and the individual or juristic profile.
module Onboarding::ProfileStep
  private
    def load_profile_step
      @record = Current.user
      @nested_records = [ @record.profile || @record.build_profile ]
    end

    def save_profile_step
      @record.assign_attributes(profile_step_params)
      @record.save(context: :profile_step)
    end

    def profile_step_params
      params.expect(onboarding: [
        :bidder_type, :first_name, :last_name, :email_address,
        profile_attributes: [
          :title, :first_name_en, :last_name_en, :national_id, :date_of_birth, :gender, :line_id, :photo,
          :company_name_th, :company_name_en, :tax_id, :company_type, :company_registered_on,
          :vat_registered, :vat_branch_code,
          :authorized_person_name, :authorized_person_national_id, :authorized_person_position,
          :contact_person_name, :contact_person_phone, :contact_person_email
        ]
      ])
    end
end
