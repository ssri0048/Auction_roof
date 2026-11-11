class Role < ApplicationRecord
  # Every permission the app knows about, with its Thai label for the admin UI.
  PERMISSIONS = {
    "manage_users"    => "จัดการผู้ใช้งาน",
    "manage_roles"    => "จัดการบทบาทและสิทธิ์",
    "create_auctions" => "สร้างรายการประมูล",
    "manage_auctions" => "จัดการรายการประมูลทั้งหมด",
    "place_bids"      => "เสนอราคาประมูล",
    "view_reports"    => "ดูรายงาน"
  }.freeze

  BUYER_NAME = "ผู้ซื้อ".freeze

  has_many :users, dependent: :restrict_with_error

  normalizes :name, with: ->(n) { n.strip }
  normalizes :permissions, with: ->(list) { Array(list).map(&:to_s).select { PERMISSIONS.key?(it) }.uniq }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }

  # Default role for self-registered users. Nil if the role was never seeded.
  def self.buyer
    find_by(name: BUYER_NAME)
  end

  def allows?(permission)
    permissions.include?(permission.to_s)
  end
end
