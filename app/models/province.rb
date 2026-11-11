class Province < ApplicationRecord
  has_many :districts, dependent: :restrict_with_error
end
