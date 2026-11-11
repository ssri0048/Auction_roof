# Step 3: the registered address plus contact and tax-invoice addresses, which
# default to "same as registered" (no separate record is kept when they are).
class Onboarding::AddressForm
  include ActiveModel::Model

  KINDS = %w[ registered contact tax_invoice ].freeze
  FIELDS = %i[ house_no moo building soi road sub_district_id selected_province_id selected_district_id ].freeze
  KIND_LABELS = { "registered" => "ที่อยู่ตามทะเบียน", "contact" => "ที่อยู่ติดต่อ", "tax_invoice" => "ที่อยู่ออกใบกำกับภาษี" }.freeze

  attr_reader :user, :contact_same, :tax_invoice_same

  def initialize(user)
    @user = user
    # Built by user_id rather than through user.addresses, so unsaved blanks don't join
    # the user's association and get validated when another address is saved.
    @addresses = KINDS.index_with { |kind| Address.find_or_initialize_by(user_id: user.id, kind: kind) }
    @contact_same = @addresses["contact"].new_record?
    @tax_invoice_same = @addresses["tax_invoice"].new_record?
  end

  KINDS.each { |kind| define_method(kind) { @addresses[kind] } }

  def assign(params)
    @contact_same = ActiveModel::Type::Boolean.new.cast(params[:contact_same])
    @tax_invoice_same = ActiveModel::Type::Boolean.new.cast(params[:tax_invoice_same])
    KINDS.each { |kind| @addresses[kind].assign_attributes(params.fetch(kind, {}).slice(*FIELDS)) if params[kind] }
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      registered.save!
      { "contact" => contact_same, "tax_invoice" => tax_invoice_same }.each do |kind, same|
        same ? (@addresses[kind].destroy! if @addresses[kind].persisted?) : @addresses[kind].save!
      end
    end
    true
  end

  def valid?
    errors.clear
    kinds_to_save.each do |kind|
      address = @addresses[kind]
      next if address.valid?

      address.errors.each { errors.add(:base, "#{KIND_LABELS[kind]}: #{it.full_message}") }
    end
    errors.empty?
  end

  private
    def kinds_to_save
      KINDS.reject { |kind| (kind == "contact" && contact_same) || (kind == "tax_invoice" && tax_invoice_same) }
    end
end
