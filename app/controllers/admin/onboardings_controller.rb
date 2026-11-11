module Admin
  # Review queue for bidder onboarding: approve, request changes or reject.
  class OnboardingsController < BaseController
    STATUSES = %w[ submitted needs_changes approved rejected in_progress ].freeze

    require_permission :manage_users
    before_action :set_user, only: %i[ show review ]

    def index
      @status = params[:status].presence_in(STATUSES) || "submitted"
      @counts = User.where(onboarding_status: STATUSES).group(:onboarding_status).count
      @users = User.where(onboarding_status: @status).where.not(bidder_type: nil).includes(:profile, :bank_accounts)
      @users = @status == "submitted" ? @users.order(:submitted_at) : @users.order(updated_at: :desc)
    end

    def show
      @checks = Onboarding::Checks.new(@user).all
      @reviews = @user.onboarding_reviews.includes(:reviewer).order(created_at: :desc)
      @review = OnboardingReview.new(bid_limit: OnboardingOptions::BUDGET_LIMITS[@user.profile&.budget_range])
    end

    def review
      unless @user.onboarding_submitted?
        return redirect_to admin_onboarding_path(@user), alert: "ตรวจได้เฉพาะผู้ที่ส่งข้อมูลแล้ว", status: :see_other
      end

      @user.review_onboarding!(reviewer: Current.user, **review_params.to_h.symbolize_keys)
      redirect_to admin_onboardings_path, notice: "บันทึกผลการตรวจ #{@user.full_name} แล้ว", status: :see_other
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_onboarding_path(@user), alert: e.record.errors.full_messages.to_sentence, status: :see_other
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      def review_params
        params.expect(review: [ :action, :comment, :bid_limit, steps_flagged: [] ])
      end
  end
end
