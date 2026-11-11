# Requires an Active Storage attachment:  validates :id_card_front, attached: true
class AttachedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, options[:message] || "ต้องอัปโหลด") unless value.attached?
  end
end
