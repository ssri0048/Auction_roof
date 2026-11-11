module Api
  module V1
    class AuctionsController < BaseController
      allow_unauthenticated_access

      # GET /api/v1/auctions?tab=live|upcoming|ended&page=1
      def index
        scope = case params[:tab]
        when "upcoming" then Auction.upcoming.order(:starts_at)
        when "ended" then Auction.finished.order(ends_at: :desc)
        else Auction.live.order(:ends_at)
        end
        page = [ params[:page].to_i, 1 ].max
        auctions = scope.includes(:seller).with_attached_photos.limit(50).offset((page - 1) * 50)
        render json: { auctions: auctions, page: page, total: scope.count }
      end

      # GET /api/v1/auctions/:id
      def show
        auction = Auction.visible.find(params[:id])
        bids = auction.price_visible? ? auction.ranked_bids.includes(:user).limit(20) : []
        render json: auction.as_json.merge(bids: bids)
      end
    end
  end
end
