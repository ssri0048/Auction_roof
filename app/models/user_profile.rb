# Step 1 (profile) and Step 2 (occupation & finance) data for a user.
# Thai first/last name, phone and email stay on `users`.
class UserProfile < ApplicationRecord
  TITLES = { "mr" => "นาย", "mrs" => "นาง", "miss" => "นางสาว", "other" => "อื่นๆ" }.freeze
  GENDERS = { "male" => "ชาย", "female" => "หญิง", "other" => "อื่นๆ / ไม่ระบุ" }.freeze
  COMPANY_TYPES = {
    "company_limited" => "บริษัทจำกัด",
    "public_company_limited" => "บริษัทมหาชนจำกัด (บมจ.)",
    "limited_partnership" => "ห้างหุ้นส่วนจำกัด (หจก.)",
    "other" => "อื่นๆ"
  }.freeze
  PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze
  MIN_AGE = 20
  AFFIDAVIT_MAX_AGE = 6.months
  MAX_SUPPORTING_DOCUMENTS = 5

  # Step 1 fields that only apply to one bidder type; the other type's are cleared on save.
  INDIVIDUAL_FIELDS = %i[ title first_name_en last_name_en national_id passport_no date_of_birth gender line_id ].freeze
  JURISTIC_FIELDS = %i[
    company_name_th company_name_en tax_id company_type company_registered_on vat_registered vat_branch_code
    authorized_person_name authorized_person_national_id authorized_person_position
    contact_person_name contact_person_phone contact_person_email
  ].freeze

  belongs_to :user, inverse_of: :profile

  # Deterministic so the columns can be looked up and have unique indexes.
  encrypts :national_id, :tax_id, deterministic: true
  encrypts :passport_no, :authorized_person_national_id

  has_one_attached :photo
  has_one_attached :id_card_front
  has_one_attached :passport_page
  has_one_attached :selfie_with_id
  has_one_attached :company_affidavit
  has_one_attached :vat_certificate
  has_one_attached :authorized_person_id_card
  has_one_attached :power_of_attorney
  has_one_attached :attorney_id_card
  has_many_attached :supporting_documents

  normalizes :national_id, :tax_id, :authorized_person_national_id, with: ->(n) { n.gsub(/\D/, "").presence }
  normalizes :passport_no, with: ->(p) { p.gsub(/\s/, "").upcase.presence }

  normalizes :first_name_en, :last_name_en, :company_name_th, :company_name_en, :authorized_person_name,
    :authorized_person_position, :contact_person_name, :line_id, with: ->(v) { v.squish.presence }
  normalizes :contact_person_phone, with: ->(p) { p.gsub(/\D/, "").presence }
  normalizes :contact_person_email, with: ->(e) { e.strip.downcase.presence }

  validates :national_id, uniqueness: true, allow_nil: true
  validates :tax_id, uniqueness: true, allow_nil: true

  # Step 1
  with_options on: :profile_step do
    with_options if: -> { user.individual? } do
      validates :title, inclusion: { in: TITLES.keys }
      validates :national_id, presence: true, thai_id: true
      validates :date_of_birth, presence: true
      validates :gender, inclusion: { in: GENDERS.keys }, allow_blank: true
      validate :old_enough
      validate :photo_type_and_size
    end

    with_options if: -> { user.juristic? } do
      validates :company_name_th, :company_registered_on, :authorized_person_name, :authorized_person_position, presence: true
      validates :tax_id, :authorized_person_national_id, presence: true, thai_id: true
      validates :company_type, inclusion: { in: COMPANY_TYPES.keys }
      validates :vat_branch_code, format: { with: /\A\d{5}\z/, message: "ต้องเป็นตัวเลข 5 หลัก (สำนักงานใหญ่ = 00000)" }, if: :vat_registered?
      validates :contact_person_phone, format: { with: /\A0\d{8,9}\z/, message: "ต้องเป็นเบอร์โทร 9-10 หลัก ขึ้นต้นด้วย 0" }, allow_nil: true
      validates :contact_person_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
    end
  end

  # Step 2
  normalizes :source_of_funds, with: ->(list) { Array(list).compact_blank.uniq }
  normalizes :occupation_other, :employer, :position, :auction_experience_note, with: ->(v) { v.squish.presence }

  with_options on: :finance_step do
    with_options if: -> { user.individual? } do
      validates :occupation, inclusion: { in: OnboardingOptions::OCCUPATIONS.keys }
      validates :occupation_other, presence: true, if: -> { occupation == "other" }
      validates :employer, presence: true, unless: -> { occupation.in?(OnboardingOptions::NO_EMPLOYER_OCCUPATIONS) }
      validates :income_range, inclusion: { in: OnboardingOptions::INCOME_RANGES.keys }
    end
    validates :revenue_range, inclusion: { in: OnboardingOptions::REVENUE_RANGES.keys }, if: -> { user.juristic? }
    validates :industry, inclusion: { in: OnboardingOptions::INDUSTRIES.keys }
    validates :source_of_funds, presence: { message: "เลือกอย่างน้อย 1 ข้อ" }
    validate :source_of_funds_are_known
    validates :purpose, inclusion: { in: OnboardingOptions::PURPOSES.keys }
    validates :budget_range, inclusion: { in: OnboardingOptions::BUDGET_RANGES.keys }
    validates :is_pep, inclusion: { in: [ true, false ], message: "กรุณาตอบ" }
  end

  # Step 4
  with_options on: :documents_step do
    validates :id_card_front, :selfie_with_id, attached: true, if: -> { user.individual? }

    with_options if: -> { user.juristic? } do
      validates :company_affidavit, :authorized_person_id_card, attached: true
      validates :company_affidavit_issued_on, presence: true
      validate :affidavit_recent_enough
      validates :vat_certificate, attached: true, if: :vat_registered?
      validates :power_of_attorney, :attorney_id_card, attached: true, unless: :account_user_is_authorized_person?
    end

    validates :supporting_documents, length: { maximum: MAX_SUPPORTING_DOCUMENTS, message: "ได้ไม่เกิน #{MAX_SUPPORTING_DOCUMENTS} ไฟล์" }
    validate :documents_type_and_size
  end

  before_save :clear_fields_for_other_bidder_type

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

  # Name the bank account should be under: the person's name or the company's.
  def legal_name
    user.juristic? ? company_name_th : user.full_name
  end

  # Every Step 4 document that is attached, as [name, attachment].
  def identity_documents
    %i[ id_card_front selfie_with_id company_affidavit vat_certificate authorized_person_id_card power_of_attorney attorney_id_card ]
      .map { [ it, public_send(it) ] }.select { |_, attachment| attachment.attached? }
  end

  private
    def affidavit_recent_enough
      return if company_affidavit_issued_on.blank? || company_affidavit_issued_on >= AFFIDAVIT_MAX_AGE.ago.to_date

      errors.add(:company_affidavit_issued_on, "ต้องออกให้ไม่เกิน 6 เดือน")
    end

    def documents_type_and_size
      identity_documents.map(&:last).concat(supporting_documents.to_a).each do |attachment|
        name = attachment.name
        errors.add(name, "ต้องเป็นไฟล์รูปภาพ (JPG/PNG/WEBP) หรือ PDF") unless attachment.content_type.in?(User::DOCUMENT_TYPES)
        errors.add(name, "ต้องมีขนาดไม่เกิน 10MB") if attachment.byte_size > 10.megabytes
      end
    end

    def source_of_funds_are_known
      unknown = source_of_funds - OnboardingOptions::SOURCES_OF_FUNDS.keys
      errors.add(:source_of_funds, "ไม่ถูกต้อง") if unknown.any?
    end

    def old_enough
      return if date_of_birth.blank?

      errors.add(:date_of_birth, "ต้องมีอายุอย่างน้อย #{MIN_AGE} ปี") if date_of_birth > MIN_AGE.years.ago.to_date
    end

    def photo_type_and_size
      return unless photo.attached?

      errors.add(:photo, "ต้องเป็นไฟล์รูปภาพ (JPG/PNG/WEBP)") unless photo.content_type.in?(PHOTO_TYPES)
      errors.add(:photo, "ต้องมีขนาดไม่เกิน 10MB") if photo.byte_size > 10.megabytes
    end

    def clear_fields_for_other_bidder_type
      fields = { "individual" => JURISTIC_FIELDS, "juristic" => INDIVIDUAL_FIELDS }[user.bidder_type]
      return unless fields

      fields.each { |field| self[field] = field == :vat_registered ? false : nil }
    end
end
