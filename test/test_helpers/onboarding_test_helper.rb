# Builds onboarding data so tests can start a user at any wizard step.
module OnboardingTestHelper
  VALID_NATIONAL_ID = "1101700203450"

  def complete_profile_step(user, bidder_type: "individual")
    user.update!(bidder_type: bidder_type, email_address: user.email_address || "#{user.username}@example.com")
    attributes =
      if bidder_type == "individual"
        { title: "mr", national_id: VALID_NATIONAL_ID, date_of_birth: Date.new(1990, 1, 1) }
      else
        { company_name_th: "บริษัท ตัวอย่าง จำกัด", tax_id: "0105556012341", company_type: "company_limited",
          company_registered_on: Date.new(2015, 1, 1), authorized_person_name: "สมหญิง ใจดี",
          authorized_person_national_id: VALID_NATIONAL_ID, authorized_person_position: "กรรมการ" }
      end
    (user.profile || user.build_profile).update!(attributes)
    advance_onboarding(user, "profile")
  end

  def complete_finance_step(user)
    user.profile.update!(occupation: "employee", employer: "บริษัท เอ", industry: "recycling", income_range: "30k_50k",
                         revenue_range: ("1m_10m" if user.juristic?), source_of_funds: %w[ salary ],
                         purpose: "resale", budget_range: "50k_200k", is_pep: false)
    advance_onboarding(user, "finance")
  end

  def sample_sub_district
    ThaiGeography.import!(file_fixture("thai_geography_sample.json"))
    SubDistrict.find_by!(code: "100101")
  end

  def complete_address_step(user)
    user.addresses.create!(kind: :registered, house_no: "1", sub_district: sample_sub_district)
    advance_onboarding(user, "address")
  end

  def complete_documents_step(user)
    image = { io: file_fixture("id_card.png").open, filename: "id_card.png", content_type: "image/png" }
    if user.individual?
      user.profile.id_card_front.attach(**image)
      user.profile.selfie_with_id.attach(**image.merge(io: file_fixture("id_card.png").open))
    else
      user.profile.update!(company_affidavit_issued_on: 1.month.ago.to_date)
      user.profile.company_affidavit.attach(**image)
      user.profile.authorized_person_id_card.attach(**image.merge(io: file_fixture("id_card.png").open))
    end
    advance_onboarding(user, "documents")
  end

  def complete_bank_step(user)
    account = user.bank_accounts.create!(bank_code: "KBANK", account_name: user.profile.legal_name, account_number: "1234567890")
    account.book_bank.attach(io: file_fixture("id_card.png").open, filename: "book_bank.png", content_type: "image/png")
    advance_onboarding(user, "bank")
    advance_onboarding(user, "interests")
  end

  def complete_consents_step(user)
    Consent::DOCUMENTS.each do |kind, document|
      user.consents.create!(kind: kind, document_version: document[:version], accepted_at: Time.current) if document[:required]
    end
    advance_onboarding(user, "consents")
  end

  # Fills in every step so the user is on "review", ready to submit.
  def complete_onboarding_steps(user, bidder_type: "individual")
    complete_profile_step(user, bidder_type: bidder_type)
    complete_finance_step(user)
    complete_address_step(user)
    complete_documents_step(user)
    complete_bank_step(user)
    complete_consents_step(user)
  end

  def advance_onboarding(user, step)
    user.complete_onboarding_step!(step)
  end
end

ActiveSupport.on_load(:active_support_test_case) { include OnboardingTestHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include OnboardingTestHelper }
