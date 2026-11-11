class User < ApplicationRecord
  OTP_LENGTH = 4
  OTP_TTL = 10.minutes
  OTP_MAX_ATTEMPTS = 5
  DOCUMENT_TYPES = %w[image/jpeg image/png image/webp application/pdf].freeze
  # Onboarding steps in order; `onboarding_step` counts how many are complete (0 = none).
  ONBOARDING_STEPS = %w[phone profile finance address documents bank interests consents review].freeze

  enum :bidder_type, { individual: "individual", juristic: "juristic" }, validate: { allow_nil: true }
  enum :onboarding_status, {
    in_progress: "in_progress",
    submitted: "submitted",
    needs_changes: "needs_changes",
    approved: "approved",
    rejected: "rejected",
    suspended: "suspended"
  }, prefix: :onboarding, validate: true

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role, optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  has_one_attached :document

  has_one :profile, class_name: "UserProfile", dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :bank_accounts, dependent: :destroy
  has_one :interest, class_name: "UserInterest", dependent: :destroy
  has_many :consents, dependent: :destroy
  has_many :onboarding_reviews, dependent: :destroy

  normalizes :username, with: ->(u) { u.strip.downcase }
  normalizes :phone, with: ->(p) { p.gsub(/\D/, "") }
  normalizes :email_address, with: ->(e) { e.strip.downcase.presence }
  normalizes :first_name, :last_name, with: ->(n) { n.strip }

  validates :username, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9_]{3,30}\z/, message: "ใช้ได้เฉพาะ a-z, 0-9, _ ความยาว 3-30 ตัว" }
  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, uniqueness: true,
    format: { with: /\A0\d{9}\z/, message: "ต้องเป็นเบอร์ 10 หลัก ขึ้นต้นด้วย 0" }
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :onboarding_step, numericality: { only_integer: true, in: 0..ONBOARDING_STEPS.length }
  validate :document_type_and_size

  # Creates a new OTP, stores only its hash, and returns the plain code so it can be sent.
  def generate_password_reset_otp!
    code = SecureRandom.random_number(10**OTP_LENGTH).to_s.rjust(OTP_LENGTH, "0")
    update_columns(otp_digest: BCrypt::Password.create(code), otp_expires_at: OTP_TTL.from_now, otp_attempts: 0)
    code
  end

  # Returns true if the code is valid. Each wrong guess counts toward the attempt limit.
  def verify_password_reset_otp(code)
    return false if otp_digest.blank? || otp_expires_at.past? || otp_attempts >= OTP_MAX_ATTEMPTS

    if BCrypt::Password.new(otp_digest).is_password?(code.to_s)
      true
    else
      increment!(:otp_attempts)
      false
    end
  end

  def clear_password_reset_otp!
    update_columns(otp_digest: nil, otp_expires_at: nil, otp_attempts: 0)
  end

  def can?(permission)
    role.present? && role.allows?(permission)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_json(*)
    {
      id: id, username: username, first_name: first_name, last_name: last_name,
      phone: phone, email_address: email_address, has_document: document.attached?,
      role: role&.name, permissions: role&.permissions || [],
      bidder_type: bidder_type, onboarding_status: onboarding_status, onboarding_step: onboarding_step,
      phone_verified: phone_verified_at.present?, created_at: created_at
    }
  end

  private
    def document_type_and_size
      return unless document.attached?

      errors.add(:document, "ต้องเป็นไฟล์รูปภาพ (JPG/PNG/WEBP) หรือ PDF") unless document.content_type.in?(DOCUMENT_TYPES)
      errors.add(:document, "ต้องมีขนาดไม่เกิน 10MB") if document.byte_size > 10.megabytes
    end
end
