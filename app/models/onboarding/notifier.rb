# Tells the user about their onboarding status, in the app and by SMS.
module Onboarding::Notifier
  MESSAGES = {
    submitted: "ได้รับข้อมูลยืนยันตัวตนแล้ว จะแจ้งผลภายใน 1–2 วันทำการ",
    approved: "ผ่านการยืนยันตัวตนแล้ว เริ่มประมูลได้เลย",
    needs_changes: "เจ้าหน้าที่ขอให้แก้ไขข้อมูลบางส่วน กรุณาเข้าสู่ระบบเพื่อแก้ไข",
    rejected: "ไม่ผ่านการยืนยันตัวตน"
  }.freeze

  def self.notify(user, event, detail = nil)
    message = [ MESSAGES.fetch(event), detail.presence ].compact.join(": ")
    Notification.create!(user: user, kind: "onboarding", message: message)
    Sms.deliver(to: user.phone, body: "Auction Roof: #{message}")
  end
end
