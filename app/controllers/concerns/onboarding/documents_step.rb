# Step 4: identity documents. A file field left empty keeps the file already uploaded.
module Onboarding::DocumentsStep
  DOCUMENT_FIELDS = %i[
    id_card_front selfie_with_id company_affidavit vat_certificate authorized_person_id_card power_of_attorney attorney_id_card
  ].freeze

  private
    def load_documents_step
      @record = Current.user.profile || Current.user.build_profile
    end

    def save_documents_step
      attributes = documents_step_params
      # An empty multi-file field sends [""], which would delete the files already there.
      attributes.delete(:supporting_documents) if Array(attributes[:supporting_documents]).compact_blank.empty?
      @record.assign_attributes(attributes.compact_blank)
      @record.save(context: :documents_step)
    end

    def documents_step_params
      params.expect(onboarding: [ :company_affidavit_issued_on, :account_user_is_authorized_person, *DOCUMENT_FIELDS, supporting_documents: [] ])
    end
end
