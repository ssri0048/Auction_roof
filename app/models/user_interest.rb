# Step 6: auction categories, pickup provinces and notification preferences.
class UserInterest < ApplicationRecord
  belongs_to :user

  normalizes :categories, :province_codes, :notify_channels, :notify_events, with: ->(list) { Array(list).compact_blank.uniq }

  validate :choices_are_known, on: :interests_step

  private
    def choices_are_known
      {
        categories: OnboardingOptions::ASSET_CATEGORIES.keys,
        province_codes: Province.pluck(:code),
        notify_channels: OnboardingOptions::NOTIFY_CHANNELS.keys,
        notify_events: OnboardingOptions::NOTIFY_EVENTS.keys
      }.each do |attribute, allowed|
        errors.add(attribute, "ไม่ถูกต้อง") if (public_send(attribute) - allowed).any?
      end
    end
end
