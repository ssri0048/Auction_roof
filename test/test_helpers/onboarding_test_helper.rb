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

  def advance_onboarding(user, step)
    user.complete_onboarding_step!(step)
  end
end

ActiveSupport.on_load(:active_support_test_case) { include OnboardingTestHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include OnboardingTestHelper }
