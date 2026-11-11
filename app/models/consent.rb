# One accepted version of a terms/rules/PDPA document (Step 7), kept as proof of consent.
class Consent < ApplicationRecord
  # The documents users agree to. Bump `version` when a text changes to ask everyone again.
  # TODO: replace the summaries with the final texts once their owners publish them (spec §8 Q5).
  DOCUMENTS = {
    "terms" => { version: "2026-11-11", required: true, title: "ข้อกำหนดการใช้งาน",
                 summary: "ข้าพเจ้าได้อ่านและยอมรับข้อกำหนดการใช้งานแพลตฟอร์ม Auction Roof" },
    "auction_rules" => { version: "2026-11-11", required: true, title: "กติกาการประมูล",
                         summary: "หลักประกัน, การริบหลักประกันเมื่อไม่ชำระเงิน, กำหนดชำระเงินและรับสินค้า และสินค้าขายตามสภาพที่เห็น" },
    "privacy_notice" => { version: "2026-11-11", required: true, title: "ประกาศความเป็นส่วนตัว (PDPA)",
                          summary: "การเก็บรวบรวมและใช้ข้อมูลส่วนบุคคลเพื่อยืนยันตัวตนและดำเนินการประมูล" },
    "marketing" => { version: "2026-11-11", required: false, title: "รับข่าวสารและโปรโมชัน",
                     summary: "ยินยอมให้ส่งข่าวสารรายการประมูลและกิจกรรมทางการตลาด" },
    "partner_sharing" => { version: "2026-11-11", required: false, title: "การเปิดเผยข้อมูลให้พันธมิตร",
                           summary: "ยินยอมให้เปิดเผยข้อมูลแก่พันธมิตรทางธุรกิจเพื่อเสนอบริการที่เกี่ยวข้อง" },
    "accuracy_declaration" => { version: "2026-11-11", required: true, title: "คำรับรองความถูกต้องของข้อมูล",
                                summary: "ข้าพเจ้าขอรับรองว่าข้อมูลและเอกสารทั้งหมดที่ให้ไว้เป็นความจริง" }
  }.freeze
  REQUIRED_KINDS = DOCUMENTS.select { |_, doc| doc[:required] }.keys.freeze

  enum :kind, DOCUMENTS.keys.index_with(&:itself), validate: true

  belongs_to :user

  scope :active, -> { where(revoked_at: nil) }

  validates :document_version, :accepted_at, presence: true

  def self.current_version(kind)
    DOCUMENTS.fetch(kind.to_s)[:version]
  end

  def current?
    revoked_at.nil? && document_version == self.class.current_version(kind)
  end
end
