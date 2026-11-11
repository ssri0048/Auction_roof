module Api
  module V1
    class UsersController < BaseController
      allow_unauthenticated_access only: :create
      rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: "too_many_requests" }, status: :too_many_requests }

      # POST /api/v1/user  (register)
      def create
        user = User.new(user_params)
        user.role = Role.buyer

        if user.save
          start_new_session_for user
          render json: user, status: :created
        else
          render json: { errors: user.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/me  (current logged-in user)
      def me
        render json: Current.user
      end

      private
        def user_params
          params.expect(user: [ :username, :first_name, :last_name, :phone, :email_address,
                                :password, :password_confirmation, :document ])
        end
    end
  end
end
