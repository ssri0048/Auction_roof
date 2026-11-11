module Admin
  class ReportsController < BaseController
    require_permission :view_reports

    def index
      @status_counts = Auction.group(:status).count
      @live_count = Auction.live.count
      @bids_count = Bid.count
      @bids_today = Bid.where(created_at: Time.current.all_day).count
      @bidders_count = Bid.distinct.count(:user_id)
      @sold = Auction.ended.where.not(winner_id: nil)
      @sold_total = @sold.sum(:current_price)
      @unsold_count = Auction.ended.where(winner_id: nil).count
      @pending_count = Auction.pending.count
      @top_auctions = Auction.visible.where("bids_count > 0").order(bids_count: :desc).limit(10)
      @recent_closed = Auction.ended.includes(:winner).order(closed_at: :desc).limit(10)
    end
  end
end
