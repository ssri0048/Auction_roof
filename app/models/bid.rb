class Bid < ApplicationRecord
  belongs_to :auction
  belongs_to :user

  validates :amount, numericality: { less_than: 1_000_000_000_000 }
  validate :bidder_allowed, :auction_open, :amount_high_enough, on: :create

  def broadcast_created
    broadcast_prepend_to auction, target: ActionView::RecordIdentifier.dom_id(auction, :bids), partial: "bids/bid", locals: { bid: self }
  end

  def as_json(*)
    { id: id, auction_id: auction_id, amount: amount.to_s, bidder: user.username, created_at: created_at }
  end

  private
    def bidder_allowed
      errors.add(:base, "คุณไม่มีสิทธิ์เสนอราคา") unless user&.can?(:place_bids)
      errors.add(:base, "ต้องยืนยันตัวตนให้ผ่านก่อนจึงจะเสนอราคาได้") if user&.can?(:place_bids) && !user.approved_bidder?
      if user&.bid_limit && amount.present? && amount > user.bid_limit
        errors.add(:amount, "เกินวงเงินประมูลของคุณ (#{ActiveSupport::NumberHelper.number_to_delimited(user.bid_limit.to_i)} บาท)")
      end
      errors.add(:base, "ไม่สามารถเสนอราคาสินค้าของตัวเองได้") if user && user == auction.seller
    end

    def auction_open
      errors.add(:base, "รายการนี้ไม่ได้เปิดรับการเสนอราคาในขณะนี้") unless auction.biddable?
    end

    def amount_high_enough
      return if amount.blank?
      if amount < auction.minimum_bid
        errors.add(:amount, "ต้องไม่ต่ำกว่า #{ActiveSupport::NumberHelper.number_to_delimited(auction.minimum_bid.to_i)} บาท")
      end
    end
end
