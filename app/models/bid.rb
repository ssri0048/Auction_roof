class Bid < ApplicationRecord
  belongs_to :auction
  belongs_to :user

  validates :amount, numericality: { greater_than: 0, less_than: 1_000_000_000_000 }
  validate :bidder_allowed, :auction_open, :amount_within_limit, :one_sealed_bid_each, on: :create

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

    def amount_within_limit
      return if amount.blank?
      if auction.reverse?
        errors.add(:amount, "ต้องไม่สูงกว่า #{baht_text(auction.maximum_bid)} บาท") if amount > auction.maximum_bid
      elsif amount < auction.minimum_bid
        errors.add(:amount, "ต้องไม่ต่ำกว่า #{baht_text(auction.minimum_bid)} บาท")
      end
    end

    def one_sealed_bid_each
      return unless auction.sealed? && user
      errors.add(:base, "การประมูลแบบยื่นซองเสนอราคาได้คนละ 1 ครั้งเท่านั้น") if auction.bids.exists?(user: user)
    end

    def baht_text(amount)
      ActiveSupport::NumberHelper.number_to_delimited(amount.to_d.round(2).to_s.sub(/\.0+\z/, ""))
    end
end
