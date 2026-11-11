class Notification < ApplicationRecord
  KINDS = %w[ outbid ending_soon won sold unsold onboarding ].freeze

  belongs_to :user
  belongs_to :auction, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_badge

  class << self
    def outbid(user, auction, bid)
      create!(user: user, auction: auction, kind: "outbid",
              message: "มีผู้เสนอราคาสูงกว่าคุณใน \"#{auction.title}\" (#{baht(bid.amount)})")
    end

    def ending_soon(auction)
      bidder_ids = auction.bids.reorder(nil).distinct.pluck(:user_id)
      User.where(id: bidder_ids).find_each do |user|
        create!(user: user, auction: auction, kind: "ending_soon", message: "\"#{auction.title}\" ใกล้ปิดประมูลแล้ว")
      end
    end

    def auction_closed(auction)
      if auction.winner
        create!(user: auction.winner, auction: auction, kind: "won",
                message: "ยินดีด้วย! คุณชนะการประมูล \"#{auction.title}\" ที่ราคา #{baht(auction.price)}")
        create!(user: auction.seller, auction: auction, kind: "sold",
                message: "\"#{auction.title}\" ปิดประมูลแล้ว ราคาสุดท้าย #{baht(auction.price)}")
      else
        create!(user: auction.seller, auction: auction, kind: "unsold",
                message: "\"#{auction.title}\" ปิดประมูลแล้วโดยไม่มีผู้เสนอราคา")
      end
    end

    private
      def baht(amount)
        "฿#{ActiveSupport::NumberHelper.number_to_delimited(amount.to_i)}"
      end
  end

  def read?
    read_at.present?
  end

  def as_json(*)
    { id: id, kind: kind, message: message, auction_id: auction_id, read: read?, created_at: created_at }
  end

  private
    def broadcast_badge
      broadcast_replace_to [ user, :notifications ], target: "notification_badge", partial: "notifications/badge", locals: { count: user.notifications.unread.count }
    end
end
