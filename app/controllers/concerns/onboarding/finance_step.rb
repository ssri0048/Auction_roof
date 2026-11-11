# Step 2: occupation, income and source of funds (stored on the profile).
module Onboarding::FinanceStep
  private
    def load_finance_step
      @record = Current.user.profile || Current.user.build_profile
    end

    def save_finance_step
      @record.assign_attributes(finance_step_params)
      @record.save(context: :finance_step)
    end

    def finance_step_params
      params.expect(onboarding: [
        :occupation, :occupation_other, :employer, :position, :industry, :income_range, :revenue_range,
        :purpose, :budget_range, :is_pep, :has_auction_experience, :auction_experience_note,
        source_of_funds: []
      ])
    end
end
