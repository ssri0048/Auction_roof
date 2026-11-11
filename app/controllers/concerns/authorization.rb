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

    def deny_access
      redirect_to root_path, alert: "คุณไม่มีสิทธิ์เข้าถึงหน้านี้"
    end
end
