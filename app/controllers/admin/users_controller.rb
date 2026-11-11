module Admin
  class UsersController < BaseController
    require_permission :manage_users
    before_action :set_user, only: %i[ show edit update ]

    def index
      @query = params[:q].to_s.strip
      @users = User.includes(:role).order(:id)
      if @query.present?
        like = "%#{User.sanitize_sql_like(@query.downcase)}%"
        @users = @users.where("username LIKE :q OR LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR phone LIKE :q", q: like)
      end
      @roles = Role.order(:name)
      @role = Role.new
    end

    def show
    end

    def edit
      @roles = Role.order(:name)
    end

    def update
      if changing_own_role?
        redirect_to after_update_path, alert: "ไม่สามารถเปลี่ยนบทบาทของตัวเองได้", status: :see_other
      elsif @user.update(user_params)
        redirect_to after_update_path, notice: "บันทึกข้อมูล #{@user.username} แล้ว", status: :see_other
      else
        @roles = Role.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.expect(user: [ :first_name, :last_name, :phone, :email_address, :role_id ])
      end

      # The inline role dropdown on the list returns to the list (keeping the search); the edit form goes to the detail page.
      def after_update_path
        params[:from] == "list" ? admin_users_path(q: params[:q].presence) : admin_user_path(@user)
      end

      # Stops an admin from locking themselves out by removing their own role.
      def changing_own_role?
        @user == Current.user && params[:user]&.key?(:role_id) && params[:user][:role_id].to_s != @user.role_id.to_s
      end
  end
end
