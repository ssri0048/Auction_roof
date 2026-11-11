class Address < ApplicationRecord
  enum :kind, { registered: "registered", contact: "contact", tax_invoice: "tax_invoice" }, validate: true

  belongs_to :user
  belongs_to :sub_district
  has_one :district, through: :sub_district
  has_one :province, through: :district

  # Form-only choices for the province → district → sub-district selects.
  attribute :selected_province_id, :integer
  attribute :selected_district_id, :integer

  normalizes :house_no, :moo, :building, :soi, :road, with: ->(v) { v.squish.presence }

  before_validation :fill_postcode_from_sub_district

  validates :kind, uniqueness: { scope: :user_id }
  validates :house_no, :postcode, presence: true

  def selected_province_id
    super || sub_district&.district&.province_id
  end

  def selected_district_id
    super || sub_district&.district_id
  end

  def to_s
    parts = [ house_no, ("หมู่ #{moo}" if moo), building, ("ซอย #{soi}" if soi), ("ถนน #{road}" if road) ]
    if sub_district
      parts += [ "ต.#{sub_district.name_th}", "อ.#{sub_district.district.name_th}", "จ.#{sub_district.district.province.name_th}" ]
    end
    (parts << postcode).compact.join(" ")
  end

  private
    # The postcode always follows the chosen sub-district.
    def fill_postcode_from_sub_district
      self.postcode = sub_district.postcode if sub_district
    end
end
