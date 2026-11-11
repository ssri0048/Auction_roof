require "test_helper"

class Admin::RolesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index" do
    get admin_roles_path
    assert_response :success
  end

  test "non-admins are turned away" do
    sign_in_as users(:two)
    post admin_roles_path, params: { role: { name: "Sneaky", permissions: [ "manage_users" ] } }
    assert_redirected_to root_path
    assert_not Role.exists?(name: "Sneaky")
  end

  test "create a role with permissions" do
    assert_difference "Role.count", 1 do
      post admin_roles_path, params: { role: { name: "Seller", permissions: [ "", "create_auctions", "place_bids" ] } }
    end
    assert_equal %w[ create_auctions place_bids ], Role.find_by!(name: "Seller").permissions
  end

  test "invalid role shows an error" do
    assert_no_difference "Role.count" do
      post admin_roles_path, params: { role: { name: "admin" } }
    end
    assert flash[:alert].present?
  end

  test "update clears permissions when all boxes are unchecked" do
    patch admin_role_path(roles(:buyer)), params: { role: { name: "Buyer", permissions: [ "" ] } }
    assert_redirected_to admin_roles_path
    assert_equal [], roles(:buyer).reload.permissions
  end

  test "cannot remove manage_roles from your own role" do
    patch admin_role_path(roles(:admin)), params: { role: { name: "Admin", permissions: [ "manage_users" ] } }
    assert_response :unprocessable_entity
    assert roles(:admin).reload.allows?(:manage_roles)
  end

  test "destroy only when unused" do
    delete admin_role_path(roles(:buyer))
    assert Role.exists?(roles(:buyer).id)

    role = Role.create!(name: "Empty")
    assert_difference "Role.count", -1 do
      delete admin_role_path(role)
    end
  end
end
