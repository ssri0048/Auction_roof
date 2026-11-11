require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup { @admin, @buyer = users(:one), users(:two) }

  test "requires login" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "users without manage_users are turned away" do
    sign_in_as @buyer
    get admin_users_path
    assert_redirected_to root_path
    patch admin_user_path(@buyer), params: { user: { role_id: roles(:admin).id } }
    assert_redirected_to root_path
    assert_equal roles(:buyer), @buyer.reload.role
  end

  test "index lists users and searches" do
    sign_in_as @admin
    get admin_users_path
    assert_response :success
    assert_select "td", text: "0822222222"

    get admin_users_path(q: "TWO")
    assert_select "td", text: "0822222222"
    assert_select "td", text: "0811111111", count: 0
  end

  test "show and edit" do
    sign_in_as @admin
    get admin_user_path(@buyer)
    assert_response :success
    get edit_admin_user_path(@buyer)
    assert_response :success
  end

  test "change a user's role from the list" do
    sign_in_as @admin
    patch admin_user_path(@buyer), params: { from: "list", q: "two", user: { role_id: roles(:admin).id } }
    assert_redirected_to admin_users_path(q: "two")
    assert_equal roles(:admin), @buyer.reload.role
  end

  test "edit details goes to the detail page" do
    sign_in_as @admin
    patch admin_user_path(@buyer), params: { user: { first_name: "Somchai", role_id: "" } }
    assert_redirected_to admin_user_path(@buyer)
    assert_equal "Somchai", @buyer.reload.first_name
    assert_nil @buyer.role
  end

  test "invalid edit re-renders" do
    sign_in_as @admin
    patch admin_user_path(@buyer), params: { user: { phone: "123" } }
    assert_response :unprocessable_entity
  end

  test "admin cannot change their own role" do
    sign_in_as @admin
    patch admin_user_path(@admin), params: { user: { role_id: "" } }
    assert_equal roles(:admin), @admin.reload.role
    assert_equal "ไม่สามารถเปลี่ยนบทบาทของตัวเองได้", flash[:alert]
  end
end
