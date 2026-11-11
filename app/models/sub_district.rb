class SubDistrict < ApplicationRecord
  belongs_to :district
  has_one :province, through: :district
end
