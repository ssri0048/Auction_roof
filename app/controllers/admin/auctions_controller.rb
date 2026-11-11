module Admin
  class AuctionsController < BaseController
    require_permission :manage_auctions
    before_action :set_auction, only: %i[ close cancel approve reject ]

    STATUSES = %w[ pending draft published ended cancelled ].freeze

    def index
      @query = params[:q].to_s.strip
      @status = params[:status].presence_in(STATUSES)
      @auctions = Auction.includes(:seller, :winner).order(created_at: :desc)
      @auctions = @auctions.where(status: @status) if @status
      if @query.present?
        @auctions = @auctions.where("title ILIKE ?", "%#{Auction.sanitize_sql_like(@query)}%")
      end
      @auctions = @auctions.limit(200)
    end

    def approve
      return redirect_to(admin_auctions_path(status: "pending"), alert: "รายการนี้ไม่ได้รออนุมัติ") unless @auction.pending?
      if @auction.approve!(Current.user)
        redirect_to admin_auctions_path(status: "pending"), notice: "อนุมัติ \"#{@auction.title}\" แล้ว"
      else
        redirect_to admin_auctions_path(status: "pending"), alert: @auction.errors.full_messages.to_sentence
      end
    end

    def reject
      return redirect_to(admin_auctions_path(status: "pending"), alert: "รายการนี้ไม่ได้รออนุมัติ") unless @auction.pending?
      @auction.reject!(params[:reason])
      redirect_to admin_auctions_path(status: "pending"), notice: "ไม่อนุมัติ \"#{@auction.title}\" แล้ว"
    end

    # Ends the auction now and picks the winner from the bids so far.
    def close
      if @auction.published?
        if @auction.ends_at.future?
          now = Time.current
          @auction.update!(starts_at: [ @auction.starts_at, now - 1.second ].min, ends_at: now)
        end
        @auction.close!
        redirect_to admin_auctions_path, notice: "ปิดประมูล \"#{@auction.title}\" แล้ว"
      else
        redirect_to admin_auctions_path, alert: "ปิดได้เฉพาะรายการที่เปิดประมูลอยู่"
      end
    end

    def cancel
      if @auction.ended?
        redirect_to admin_auctions_path, alert: "ยกเลิกรายการที่ปิดแล้วไม่ได้"
      else
        @auction.update!(status: "cancelled")
        redirect_to admin_auctions_path, notice: "ยกเลิก \"#{@auction.title}\" แล้ว"
      end
    end

    private
      def set_auction
        @auction = Auction.find(params[:id])
      end
  end
end
