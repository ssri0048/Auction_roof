# Validates a 13-digit Thai national ID or juristic tax ID, including its check digit.
#   validates :national_id, thai_id: true
class ThaiIdValidator < ActiveModel::EachValidator
  def self.valid?(value)
    digits = value.to_s
    return false unless digits.match?(/\A\d{13}\z/)

    sum = digits[0, 12].chars.each_with_index.sum { |digit, index| digit.to_i * (13 - index) }
    (11 - sum % 11) % 10 == digits[12].to_i
  end

  def validate_each(record, attribute, value)
    return if value.blank? || self.class.valid?(value)

    record.errors.add(attribute, options[:message] || "ไม่ถูกต้อง (ต้องเป็นเลข 13 หลักที่ถูกต้อง)")
  end
end
