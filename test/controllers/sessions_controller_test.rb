require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
    assert_select "input[name=username]"
    assert_select "a[href=?]", new_password_reset_path
    assert_select "a[href=?]", new_registration_path
  end

  test "create with valid credentials (username is case-insensitive)" do
    post session_path, params: { username: " ONE ", password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create sends a bidder with pending onboarding to the wizard" do
    post session_path, params: { username: "two", password: "password" }

    assert_redirected_to onboarding_url
  end

  test "create with invalid credentials" do
    post session_path, params: { username: @user.username, password: "wrong" }

    assert_redirected_to new_session_path(username: @user.username)
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
