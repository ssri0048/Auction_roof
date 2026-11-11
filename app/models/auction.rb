class Auction < ApplicationRecord
  PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTOS = 10
  ENDING_SOON = 10.minutes

  TYPES = {
    "english" => "English (ราคาขึ้น เปิดเผย)",
    "first_price_sealed" => "First-price sealed (ยื่นซอง จ่ายราคาที่เสนอ)",
    "second_price_sealed" => "Second-price sealed (ยื่นซอง จ่ายราคาอันดับสอง)",
    "reverse" => "Reverse (ราคาลง ต่ำสุดชนะ)"
  }.freeze
  SEALED_TYPES = %w[first_price_sealed second_price_sealed].freeze

  enum :status, { draft: "draft", pending: "pending", published: "published", ended: "ended", cancelled: "cancelled" }, default: "draft"
  # scopes: false because a `reverse` scope would clash with Relation#reverse.
  enum :auction_type, TYPES.keys.index_by(&:itself), default: "english", validate: true, scopes: false

  belongs_to :seller, class_name: "User"
  belongs_to :winner, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :bids, dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many_attached :photos

  normalizes :title, with: ->(t) { t.strip }

  validates :title, presence: true, length: { maximum: 200 }
  validates :starting_price, numericality: { greater_than: 0, less_than: 1_000_000_000_000 }
  validates :min_increment, numericality: { greater_than: 0, less_than: 1_000_000_000_000 }, unless: :sealed?
  validates :starts_at, :ends_at, presence: true
  validates :rejection_reason, length: { maximum: 255 }
  validate :ends_after_start
  validate :photos_type_size_and_count
  validate :type_locked_after_bids, on: :update

  before_validation -> { self.min_increment = nil }, if: :sealed?
  after_save_commit :schedule_jobs, if: -> { published? && (saved_change_to_status? || saved_change_to_ends_at?) }
  after_update_commit :broadcast_price

  scope :visible, -> { where(status: %w[published ended]) }
  scope :live, -> { published.where(starts_at: ..Time.current).where("ends_at > ?", Time.current) }
  scope :upcoming, -> { published.where("starts_at > ?", Time.current) }
  scope :finished, -> { where(status: "ended").or(published.where(ends_at: ..Time.current)) }
  scope :due_to_close, -> { published.where(ends_at: ..Time.current) }

  # draft | pending | upcoming | live | closing (time is up, job not run yet) | ended | cancelled
  def phase
    return status.to_sym unless published?
    now = Time.current
    if now < starts_at then :upcoming
    elsif now < ends_at then :live
    else :closing
    end
  end

  def biddable?
    phase == :live
  end

  def sealed?
    auction_type.in?(SEALED_TYPES)
  end

  # Sealed prices stay hidden until the auction closes.
  def price_visible?
    !sealed? || ended?
  end

  def price
    current_price || starting_price
  end

  # English: the next bid must be at least this.
  # Sealed: the reserve price. Reverse: not used (see maximum_bid).
  def minimum_bid
    return starting_price if sealed? || bids_count.zero?
    current_price + min_increment
  end

  # Reverse: the next bid must be at most this.
  def maximum_bid
    bids_count.zero? ? starting_price : current_price - min_increment
  end

  # Best bid first: lowest for reverse, highest otherwise. Ties go to the earlier bid.
  def ranked_bids
    bids.order(amount: (reverse? ? :asc : :desc), id: :asc)
  end

  def editable_by?(user)
    return false unless user
    return true if user.can?(:manage_auctions) && !ended?
    user == seller && user.can?(:create_auctions) &&
      (draft? || pending? || (published? && bids_count.zero? && phase == :upcoming))
  end

  # Sends the auction for review. Users who can approve publish straight away.
  def submit_by(user)
    if user.can?(:manage_auctions)
      self.status = "published"
      self.approved_by = user
      self.approved_at = Time.current
    else
      self.status = "pending"
    end
    self.rejection_reason = nil
  end

  def approve!(admin)
    raise ArgumentError, "not pending" unless pending?
    if ends_at.past?
      errors.add(:base, "เวลาปิดผ่านไปแล้ว กรุณาให้ผู้ขายแก้เวลาก่อน")
      return false
    end
    update!(status: "published", approved_by: admin, approved_at: Time.current, rejection_reason: nil)
    Notification.reviewed(self)
    true
  end

  def reject!(reason)
    raise ArgumentError, "not pending" unless pending?
    update!(status: "draft", rejection_reason: reason.to_s.strip.presence || "ไม่ระบุเหตุผล")
    Notification.reviewed(self)
  end

  # Places a bid under a row lock so two bidders can't both win the same price.
  # Returns the Bid (check bid.persisted? / bid.errors).
  def place_bid(user:, amount:)
    previous_leader = nil
    bid = nil

    with_lock do
      bid = Bid.new(auction: self, user: user, amount: amount)
      if bid.save
        if sealed?
          update!(bids_count: bids_count + 1) # keep the price secret
        else
          previous_leader = ranked_bids.where.not(id: bid.id).first&.user
          update!(current_price: bid.amount, bids_count: bids_count + 1)
        end
      end
    end

    if bid.persisted?
      bid.broadcast_created unless sealed?
      Notification.outbid(previous_leader, self, bid) if previous_leader && previous_leader != user
    end
    bid
  end

  # Ends the auction once its time is up, picks the winner and sets the final price.
  # Safe to call more than once.
  def close!
    closed = false
    with_lock do
      next unless published? && ends_at <= Time.current
      first, second = ranked_bids.limit(2).to_a
      update!(status: "ended", closed_at: Time.current, winner: first&.user,
              current_price: first ? final_price(first, second) : current_price)
      closed = true
    end
    Notification.auction_closed(self) if closed
    closed
  end

  def notify_ending_soon!
    claimed = Auction.where(id: id, ending_soon_notified_at: nil).update_all(ending_soon_notified_at: Time.current) == 1
    Notification.ending_soon(self) if claimed && biddable?
  end

  def as_json(*)
    {
      id: id, title: title, description: description, auction_type: auction_type,
      seller: { id: seller_id, name: seller.full_name },
      starting_price: starting_price.to_s, min_increment: min_increment&.to_s,
      current_price: (price.to_s if price_visible?),
      minimum_bid: (minimum_bid.to_s unless reverse?), maximum_bid: (maximum_bid.to_s if reverse?),
      bids_count: bids_count, starts_at: starts_at, ends_at: ends_at, status: status, phase: phase,
      winner_id: winner_id, photos: photo_paths
    }
  end

  private
    # Second-price sealed: the winner pays the runner-up's bid, or the reserve if nobody else bid.
    def final_price(first, second)
      return first.amount unless second_price_sealed?
      second&.amount || starting_price
    end

    def photo_paths
      photos.map { Rails.application.routes.url_helpers.rails_blob_path(it, only_path: true) }
    end

    def ends_after_start
      return if starts_at.blank? || ends_at.blank?
      errors.add(:ends_at, "ต้องอยู่หลังเวลาเริ่ม") if ends_at <= starts_at
    end

    def type_locked_after_bids
      errors.add(:auction_type, "เปลี่ยนไม่ได้หลังมีผู้เสนอราคาแล้ว") if auction_type_changed? && bids_count.positive?
    end

    def photos_type_size_and_count
      return unless photos.attached?
      errors.add(:photos, "ใส่ได้สูงสุด #{MAX_PHOTOS} รูป") if photos.size > MAX_PHOTOS
      photos.each do |photo|
        errors.add(:photos, "ต้องเป็นไฟล์ JPG/PNG/WEBP") unless photo.content_type.in?(PHOTO_TYPES)
        errors.add(:photos, "แต่ละรูปต้องไม่เกิน 10MB") if photo.byte_size > 10.megabytes
      end
    end

    def schedule_jobs
      CloseAuctionJob.set(wait_until: ends_at).perform_later(self)
      warn_at = ends_at - ENDING_SOON
      EndingSoonJob.set(wait_until: warn_at).perform_later(self) if warn_at.future?
    end

    def broadcast_price
      broadcast_replace_to self, target: ActionView::RecordIdentifier.dom_id(self, :price), partial: "auctions/price", locals: { auction: self }
      broadcast_replace_to :auctions, target: ActionView::RecordIdentifier.dom_id(self, :card_price), partial: "auctions/card_price", locals: { auction: self }
    end
end
