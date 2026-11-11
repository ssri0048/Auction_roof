# Step 7: one checkbox per document. Accepting records the document version, time
# and IP; unticking an optional consent revokes it.
class Onboarding::ConsentForm
  include ActiveModel::Model

  attr_reader :user, :accepted

  def initialize(user)
    @user = user
    @accepted = user.consents.active.select(&:current?).map(&:kind)
  end

  def accepted?(kind)
    accepted.include?(kind)
  end

  def assign(params)
    @accepted = Consent::DOCUMENTS.keys.select { |kind| ActiveModel::Type::Boolean.new.cast(params[kind]) }
  end

  def save(ip_address:)
    return false unless valid?

    now = Time.current
    Consent.transaction do
      Consent::DOCUMENTS.each_key do |kind|
        active = user.consents.active.where(kind: kind)
        if accepted?(kind)
          next if active.any?(&:current?)

          active.update_all(revoked_at: now)
          user.consents.create!(kind: kind, document_version: Consent.current_version(kind), accepted_at: now, ip_address: ip_address)
        else
          active.update_all(revoked_at: now)
        end
      end
    end
    true
  end

  def valid?
    errors.clear
    (Consent::REQUIRED_KINDS - accepted).each { errors.add(:base, "ต้องยอมรับ \"#{Consent::DOCUMENTS[it][:title]}\"") }
    errors.empty?
  end
end
