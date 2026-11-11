require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def valid_params
    { user: { username: "newbie", first_name: "สมชาย", last_name: "ใจดี", phone: "081-234-5678",
              password: "password123", password_confirmation: "password123",
              document: fixture_file_upload("id_card.png", "image/png") } }
  end

  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create signs the user in and stores the document" do
    assert_difference "User.count", 1 do
      post registration_path, params: valid_params
    end

    assert_redirected_to onboarding_path
    assert cookies[:session_id]
    user = User.find_by!(username: "newbie")
    assert_equal "0812345678", user.phone
    assert user.document.attached?
  end

  test "create assigns the buyer role by default" do
    buyer = Role.create!(name: Role::BUYER_NAME, permissions: %w[place_bids])

    post registration_path, params: valid_params

    assert_equal buyer, User.find_by!(username: "newbie").role
  end

  test "create with invalid data re-renders the form" do
    params = valid_params
    params[:user][:phone] = "123"

    assert_no_difference "User.count" do
      post registration_path, params: params
    end
    assert_response :unprocessable_entity
  end

  test "rejects disallowed document types" do
    params = valid_params
    params[:user][:document] = fixture_file_upload("evil.txt", "text/plain")

    assert_no_difference "User.count" do
      post registration_path, params: params
    end
    assert_response :unprocessable_entity
  end
end
