# One accepted version of a terms/rules/PDPA document (Step 7), kept as proof of consent.
class Consent < ApplicationRecord
  enum :kind, {
    terms: "terms",
    auction_rules: "auction_rules",
    privacy_notice: "privacy_notice",
    marketing: "marketing",
    partner_sharing: "partner_sharing",
    accuracy_declaration: "accuracy_declaration"
  }, validate: true

  belongs_to :user

  scope :active, -> { where(revoked_at: nil) }

  validates :document_version, :accepted_at, presence: true
end
