# Step 5: the bank account deposits are refunded to.
module Onboarding::BankStep
  private
    def load_bank_step
      @record = Current.user.bank_accounts.first || Current.user.bank_accounts.build(account_name: Current.user.profile&.legal_name)
    end

    def save_bank_step
      attributes = bank_step_params
      attributes.delete(:book_bank) if attributes[:book_bank].blank?
      @record.assign_attributes(attributes)
      @record.save(context: :bank_step)
    end

    def bank_step_params
      params.expect(onboarding: [ :bank_code, :account_name, :account_number, :branch, :book_bank ])
    end
end
