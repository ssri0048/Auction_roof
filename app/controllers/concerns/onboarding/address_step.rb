# Step 3: registered, contact and tax-invoice addresses.
module Onboarding::AddressStep
  private
    def load_address_step
      @record = Onboarding::AddressForm.new(Current.user)
    end

    def save_address_step
      @record.assign(address_step_params)
      @record.save
    end

    def address_step_params
      fields = Onboarding::AddressForm::FIELDS
      params.expect(onboarding: [ :contact_same, :tax_invoice_same, registered: fields, contact: fields, tax_invoice: fields ])
    end
end
