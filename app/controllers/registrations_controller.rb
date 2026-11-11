class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "ลองใหม่อีกครั้งในภายหลัง" }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = Role.buyer

    if @user.save
      start_new_session_for @user
      redirect_to (@user.onboarding_pending? ? onboarding_path : root_path), notice: "สมัครสมาชิกสำเร็จ"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.expect(user: [ :username, :first_name, :last_name, :phone, :email_address,
                            :password, :password_confirmation, :document ])
    end
end
