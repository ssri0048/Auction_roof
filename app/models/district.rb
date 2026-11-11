class District < ApplicationRecord
  belongs_to :province
  has_many :sub_districts, dependent: :restrict_with_error
end
