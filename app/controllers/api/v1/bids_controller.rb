module Api
  module V1
    class BidsController < BaseController
      rate_limit to: 30, within: 1.minute, with: -> { render json: { error: "too_many_requests" }, status: :too_many_requests }

      # POST /api/v1/auctions/:auction_id/bids  { "bid": { "amount": "12500" } }
      def create
        return render(json: { error: "forbidden" }, status: :forbidden) unless can?(:place_bids)
        return render(json: { error: "onboarding_not_approved" }, status: :forbidden) unless Current.user.approved_bidder?

        auction = Auction.visible.find(params[:auction_id])
        bid = auction.place_bid(user: Current.user, amount: params.expect(bid: [ :amount ])[:amount])
        if bid.persisted?
          render json: bid.as_json.merge(auction: auction.reload), status: :created
        else
          render json: { errors: bid.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end
    end
  end
end
