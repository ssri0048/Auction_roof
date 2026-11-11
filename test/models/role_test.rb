require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "drops unknown and blank permissions" do
    role = Role.create!(name: "Seller", permissions: [ "", "place_bids", "hack_the_planet", "place_bids" ])
    assert_equal [ "place_bids" ], role.reload.permissions
  end

  test "name must be unique" do
    assert_not Role.new(name: "admin").valid?
  end

  test "user can? follows role permissions" do
    assert users(:one).can?(:manage_users)
    assert_not users(:two).can?(:manage_users)
    assert_not User.new.can?(:place_bids)
  end

  test "cannot destroy a role that still has users" do
    assert_not roles(:buyer).destroy
    assert Role.exists?(roles(:buyer).id)
  end
end
