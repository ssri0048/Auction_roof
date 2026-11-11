module Admin
  class RolesController < BaseController
    require_permission :manage_roles
    before_action :set_role, only: %i[ edit update destroy ]

    def index
      @roles = Role.left_joins(:users).group(:id).select("roles.*, COUNT(users.id) AS users_count").order(:name)
      @role = Role.new
    end

    def edit
    end

    def create
      @role = Role.new(role_params)

      if @role.save
        redirect_back_or_to admin_roles_path, notice: "เพิ่มบทบาท #{@role.name} แล้ว", status: :see_other
      else
        redirect_back_or_to admin_roles_path, alert: @role.errors.full_messages.to_sentence, status: :see_other
      end
    end

    def update
      @role.assign_attributes(role_params)

      if removes_own_admin_access?
        @role.errors.add(:base, "ไม่สามารถนำสิทธิ์จัดการบทบาทออกจากบทบาทของตัวเองได้")
        render :edit, status: :unprocessable_entity
      elsif @role.save
        redirect_to admin_roles_path, notice: "บันทึกบทบาท #{@role.name} แล้ว", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @role.destroy
        redirect_to admin_roles_path, notice: "ลบบทบาท #{@role.name} แล้ว", status: :see_other
      else
        redirect_to admin_roles_path, alert: "ลบไม่ได้: ยังมีผู้ใช้งานในบทบาทนี้", status: :see_other
      end
    end

    private
      def set_role
        @role = Role.find(params[:id])
      end

      # Unchecking every box sends no permissions key, so default to an empty list.
      def role_params
        params.expect(role: [ :name, permissions: [] ]).with_defaults(permissions: [])
      end

      def removes_own_admin_access?
        Current.user.role_id == @role.id && !@role.allows?(:manage_roles)
      end
  end
end
