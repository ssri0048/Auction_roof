# Account used to refund deposits to unsuccessful bidders (Step 5).
class BankAccount < ApplicationRecord
  # Ignored when comparing the account name with the profile name.
  NAME_NOISE = /\s|\.|นางสาว|นาย|นาง|น\.ส|mr|mrs|ms|miss/i

  belongs_to :user

  encrypts :account_number
  has_one_attached :book_bank

  normalizes :account_number, with: ->(n) { n.gsub(/\D/, "") }
  normalizes :account_name, :branch, with: ->(n) { n.squish.presence }

  with_options on: :bank_step do
    validates :bank_code, inclusion: { in: OnboardingOptions::BANKS.keys }
    validates :account_name, presence: true
    validates :account_number, format: { with: /\A\d{10,15}\z/, message: "ต้องเป็นตัวเลข 10–15 หลัก" }
    validates :book_bank, attached: true
    validate :book_bank_type_and_size
  end

  def bank_name
    OnboardingOptions::BANKS[bank_code]
  end

  # Shows only the last 4 digits: "xxxxxx1234".
  def masked_account_number
    return if account_number.blank?

    "#{"x" * [ account_number.length - 4, 0 ].max}#{account_number.last(4)}"
  end

  # Whether the account is in the bidder's own (or company's) name. A mismatch is flagged for review.
  def name_matches_profile?
    expected = user.profile&.legal_name
    return false if account_name.blank? || expected.blank?

    account_name.gsub(NAME_NOISE, "").include?(expected.gsub(NAME_NOISE, ""))
  end

  private
    def book_bank_type_and_size
      return unless book_bank.attached?

      errors.add(:book_bank, "ต้องเป็นไฟล์รูปภาพ (JPG/PNG/WEBP) หรือ PDF") unless book_bank.content_type.in?(User::DOCUMENT_TYPES)
      errors.add(:book_bank, "ต้องมีขนาดไม่เกิน 10MB") if book_bank.byte_size > 10.megabytes
    end
end
