class BidsController < ApplicationController
  require_permission :place_bids
  before_action :require_approved_bidder
  rate_limit to: 30, within: 1.minute, only: :create

  def create
    @auction = Auction.find(params[:auction_id])
    @bid = @auction.place_bid(user: Current.user, amount: params.expect(bid: [ :amount ])[:amount])

    if @bid.persisted?
      redirect_to @auction, notice: "เสนอราคา #{helpers.baht(@bid.amount)} แล้ว"
    else
      redirect_to @auction, alert: @bid.errors.full_messages.to_sentence
    end
  end
end
