class Address < ApplicationRecord
  enum :kind, { registered: "registered", contact: "contact", tax_invoice: "tax_invoice" }, validate: true

  belongs_to :user
  belongs_to :sub_district
  has_one :district, through: :sub_district
  has_one :province, through: :district

  normalizes :house_no, :moo, :building, :soi, :road, with: ->(v) { v.squish.presence }

  before_validation :fill_postcode_from_sub_district

  validates :kind, uniqueness: { scope: :user_id }
  validates :house_no, :postcode, presence: true

  private
    def fill_postcode_from_sub_district
      self.postcode = sub_district.postcode if postcode.blank? && sub_district
    end
end
