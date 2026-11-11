module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :can?
  end

  class_methods do
    # Role-based access control: require_permission :manage_users, only: %i[ update ]
    def require_permission(permission, **options)
      before_action(**options) { deny_access unless can?(permission) }
    end
  end

  private
    def can?(permission)
      Current.user&.can?(permission) || false
    end

    # For bidding and deposits: the user must have passed onboarding review.
    def require_approved_bidder
      return if Current.user&.approved_bidder?

      redirect_to (Current.user&.onboarding_pending? ? onboarding_path : root_path),
        alert: "ต้องยืนยันตัวตนให้ผ่านก่อนจึงจะเสนอราคาได้"
    end

    def deny_access
      redirect_to root_path, alert: "คุณไม่มีสิทธิ์เข้าถึงหน้านี้"
    end
end
