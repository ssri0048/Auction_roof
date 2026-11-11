# Step 1 (profile) and Step 2 (occupation & finance) data for a user.
# Thai first/last name, phone and email stay on `users`.
class UserProfile < ApplicationRecord
  belongs_to :user

  # Deterministic so the columns can be looked up and have unique indexes.
  encrypts :national_id, :tax_id, deterministic: true
  encrypts :passport_no, :authorized_person_national_id

  has_one_attached :id_card_front
  has_one_attached :passport_page
  has_one_attached :selfie_with_id
  has_one_attached :company_affidavit
  has_one_attached :vat_certificate
  has_one_attached :authorized_person_id_card
  has_one_attached :power_of_attorney

  normalizes :national_id, :tax_id, :authorized_person_national_id, with: ->(n) { n.gsub(/\D/, "").presence }
  normalizes :passport_no, with: ->(p) { p.gsub(/\s/, "").upcase.presence }

  validates :national_id, uniqueness: true, allow_nil: true
  validates :tax_id, uniqueness: true, allow_nil: true

  # Formats a 13-digit Thai ID showing only the last 3 digits: "x-xxxx-xxxxx-12-3".
  def self.mask_thai_id(value)
    return if value.blank?

    digits = value.to_s.gsub(/\D/, "")
    return "x" * digits.length unless digits.length == 13

    "x-xxxx-xxxxx-#{digits[10, 2]}-#{digits[12]}"
  end

  def masked_national_id
    self.class.mask_thai_id(national_id)
  end

  def masked_tax_id
    self.class.mask_thai_id(tax_id)
  end

  def masked_authorized_person_national_id
    self.class.mask_thai_id(authorized_person_national_id)
  end

  def masked_passport_no
    return if passport_no.blank?

    "#{"x" * [ passport_no.length - 3, 0 ].max}#{passport_no.last(3)}"
  end
end
