# Choices offered in the onboarding steps, as { stored value => Thai label }.
module OnboardingOptions
  STEP_LABELS = {
    "profile" => "ข้อมูลส่วนตัว",
    "finance" => "อาชีพและรายได้",
    "address" => "ที่อยู่",
    "documents" => "เอกสารยืนยันตัวตน",
    "bank" => "บัญชีรับเงินคืน",
    "interests" => "ความสนใจ",
    "consents" => "ข้อตกลงและความยินยอม",
    "review" => "ตรวจสอบและยืนยัน"
  }.freeze

  OCCUPATIONS = {
    "employee" => "พนักงานบริษัท",
    "government" => "ข้าราชการ / รัฐวิสาหกิจ",
    "business_owner" => "เจ้าของกิจการ",
    "merchant" => "ค้าขาย",
    "contractor" => "รับเหมา",
    "farmer" => "เกษตรกร",
    "freelance" => "ฟรีแลนซ์",
    "student" => "นักศึกษา",
    "retired" => "เกษียณ",
    "other" => "อื่นๆ (ระบุ)"
  }.freeze
  # These occupations have no employer or business to name.
  NO_EMPLOYER_OCCUPATIONS = %w[ student retired ].freeze

  INDUSTRIES = {
    "recycling" => "รีไซเคิล / ค้าเศษวัสดุ",
    "logistics" => "ขนส่ง / โลจิสติกส์",
    "construction" => "ก่อสร้าง / รับเหมา",
    "electrical" => "ไฟฟ้า / อิเล็กทรอนิกส์",
    "manufacturing" => "ผลิต / อุตสาหกรรม",
    "automotive" => "ยานยนต์",
    "trading" => "ค้าปลีก / ค้าส่ง",
    "agriculture" => "เกษตร",
    "services" => "บริการ",
    "public_sector" => "ราชการ / รัฐวิสาหกิจ",
    "other" => "อื่นๆ"
  }.freeze

  INCOME_RANGES = {
    "lt_15k" => "ต่ำกว่า 15,000 บาท",
    "15k_30k" => "15,000 – 30,000 บาท",
    "30k_50k" => "30,001 – 50,000 บาท",
    "50k_100k" => "50,001 – 100,000 บาท",
    "100k_300k" => "100,001 – 300,000 บาท",
    "gt_300k" => "มากกว่า 300,000 บาท"
  }.freeze

  REVENUE_RANGES = {
    "lt_1m" => "ต่ำกว่า 1 ล้านบาท",
    "1m_10m" => "1 – 10 ล้านบาท",
    "10m_50m" => "10 – 50 ล้านบาท",
    "50m_100m" => "50 – 100 ล้านบาท",
    "gt_100m" => "มากกว่า 100 ล้านบาท"
  }.freeze

  SOURCES_OF_FUNDS = {
    "salary" => "เงินเดือน",
    "business_income" => "รายได้ธุรกิจ",
    "savings" => "เงินออม",
    "loan" => "สินเชื่อ",
    "other" => "อื่นๆ"
  }.freeze

  PURPOSES = {
    "personal" => "ใช้เอง",
    "business_use" => "ใช้ในกิจการ",
    "resale" => "ขายต่อ",
    "recycling" => "รีไซเคิล"
  }.freeze

  BUDGET_RANGES = {
    "lt_50k" => "ไม่เกิน 50,000 บาท",
    "50k_200k" => "50,001 – 200,000 บาท",
    "200k_1m" => "200,001 – 1,000,000 บาท",
    "1m_5m" => "1 – 5 ล้านบาท",
    "gt_5m" => "มากกว่า 5 ล้านบาท"
  }.freeze
  # Upper bound of each budget range, used to pre-fill bid_limit on approval (nil = no cap).
  BUDGET_LIMITS = { "lt_50k" => 50_000, "50k_200k" => 200_000, "200k_1m" => 1_000_000, "1m_5m" => 5_000_000, "gt_5m" => nil }.freeze

  BANKS = {
    "BBL" => "ธนาคารกรุงเทพ",
    "KBANK" => "ธนาคารกสิกรไทย",
    "KTB" => "ธนาคารกรุงไทย",
    "SCB" => "ธนาคารไทยพาณิชย์",
    "BAY" => "ธนาคารกรุงศรีอยุธยา",
    "TTB" => "ธนาคารทหารไทยธนชาต",
    "GSB" => "ธนาคารออมสิน",
    "BAAC" => "ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร (ธ.ก.ส.)",
    "GHB" => "ธนาคารอาคารสงเคราะห์",
    "UOB" => "ธนาคารยูโอบี",
    "CIMBT" => "ธนาคารซีไอเอ็มบี ไทย",
    "KKP" => "ธนาคารเกียรตินาคินภัทร",
    "TISCO" => "ธนาคารทิสโก้",
    "LHB" => "ธนาคารแลนด์ แอนด์ เฮ้าส์",
    "ICBCT" => "ธนาคารไอซีบีซี (ไทย)",
    "IBANK" => "ธนาคารอิสลามแห่งประเทศไทย"
  }.freeze

  ASSET_CATEGORIES = {
    "vehicles" => "ยานพาหนะ",
    "transformers" => "หม้อแปลงไฟฟ้า",
    "cables_scrap" => "สายไฟ / เศษโลหะ",
    "electrical_equipment" => "อุปกรณ์ไฟฟ้า",
    "machinery" => "เครื่องจักร",
    "office_equipment" => "ครุภัณฑ์สำนักงาน",
    "other" => "อื่นๆ"
  }.freeze

  NOTIFY_CHANNELS = { "sms" => "SMS", "email" => "อีเมล", "line" => "LINE" }.freeze

  NOTIFY_EVENTS = {
    "new_auction" => "มีรายการใหม่ในหมวดที่สนใจ",
    "auction_starting" => "การประมูลกำลังจะเริ่ม",
    "outbid" => "มีผู้เสนอราคาสูงกว่า",
    "won" => "ชนะการประมูล",
    "payment_due" => "ใกล้ครบกำหนดชำระเงิน",
    "refund_sent" => "คืนเงินหลักประกันแล้ว"
  }.freeze
end
