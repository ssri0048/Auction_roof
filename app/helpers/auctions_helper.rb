module AuctionsHelper
  PHASE_LABELS = {
    draft: "ร่าง", pending: "รออนุมัติ", upcoming: "เร็ว ๆ นี้", live: "กำลังประมูล",
    closing: "กำลังปิด", ended: "ปิดประมูลแล้ว", cancelled: "ยกเลิก"
  }.freeze

  TYPE_SHORT = {
    "english" => "English", "first_price_sealed" => "First-price sealed",
    "second_price_sealed" => "Second-price sealed", "reverse" => "Reverse"
  }.freeze

  TYPE_HELP = {
    "english" => "เสนอราคาแบบเปิดเผย ราคาขึ้นทีละขั้น ราคาสูงสุดเมื่อหมดเวลาชนะ",
    "first_price_sealed" => "ยื่นซองเสนอราคาได้คนละ 1 ครั้ง ไม่เห็นราคาของคนอื่น ราคาสูงสุดชนะและจ่ายตามราคาที่เสนอ",
    "second_price_sealed" => "ยื่นซองเสนอราคาได้คนละ 1 ครั้ง ไม่เห็นราคาของคนอื่น ราคาสูงสุดชนะ แต่จ่ายเท่ากับราคาอันดับสอง",
    "reverse" => "เสนอราคาแบบเปิดเผย ราคาลงทีละขั้นจากราคาเพดาน ราคาต่ำสุดเมื่อหมดเวลาชนะ"
  }.freeze

  def auction_type_badge(auction)
    tag.span(TYPE_SHORT[auction.auction_type], class: "type-badge type-badge--#{auction.auction_type}", title: TYPE_HELP[auction.auction_type])
  end

  # Price shown on cards and tables. Sealed auctions keep it hidden until they close.
  def display_price(auction)
    auction.price_visible? ? baht(auction.price) : "ปิดผนึก"
  end

  def starting_price_label(auction)
    if auction.reverse? then "ราคาเพดาน"
    elsif auction.sealed? then "ราคาขั้นต่ำ"
    else "ราคาเริ่มต้น"
    end
  end

  def baht(amount)
    "฿#{number_with_delimiter(amount.to_d.round(2).to_s.sub(/\.0+\z/, ""))}"
  end

  # Bidders see each other only as "som***" to keep identities private.
  def mask_name(user)
    name = user.username
    "#{name[0, 3]}***"
  end

  def phase_badge(auction)
    phase = auction.phase
    tag.span(PHASE_LABELS[phase], class: "phase phase--#{phase}")
  end

  def thai_datetime(time)
    time&.in_time_zone&.strftime("%d/%m/%Y %H:%M")
  end

  def auction_cover(auction, **options)
    if auction.photos.attached?
      image_tag rails_blob_path(auction.photos.first, disposition: "inline"), alt: auction.title, loading: "lazy", **options
    else
      tag.div("ไม่มีรูป", class: "cover-placeholder")
    end
  end
end
