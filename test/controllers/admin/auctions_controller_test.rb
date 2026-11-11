require "test_helper"

class Admin::AuctionsControllerTest < ActionDispatch::IntegrationTest
  test "requires manage_auctions" do
    sign_in_as users(:three)
    get admin_auctions_path
    assert_redirected_to root_path
    post close_admin_auction_path(auctions(:live))
    assert auctions(:live).reload.published?
  end

  test "lists and filters auctions" do
    sign_in_as users(:one)
    get admin_auctions_path
    assert_response :success
    assert_select "td a", text: auctions(:draft).title

    get admin_auctions_path(status: "draft")
    assert_select "td a", text: auctions(:live).title, count: 0
  end

  test "close now ends a live auction with the current leader" do
    auction = auctions(:live)
    auction.place_bid(user: users(:two), amount: 10000)
    sign_in_as users(:one)
    post close_admin_auction_path(auction)
    assert_redirected_to admin_auctions_path
    assert auction.reload.ended?
    assert_equal users(:two), auction.winner
  end

  test "close now also works on an upcoming auction" do
    sign_in_as users(:one)
    post close_admin_auction_path(auctions(:upcoming))
    assert auctions(:upcoming).reload.ended?
  end

  test "approve and reject pending auctions" do
    sign_in_as users(:one)
    get admin_auctions_path(status: "pending")
    assert_select "td a", text: auctions(:pending).title
    assert_select "button", text: "อนุมัติ"

    post approve_admin_auction_path(auctions(:pending))
    assert_redirected_to admin_auctions_path(status: "pending")
    assert auctions(:pending).reload.published?

    auctions(:draft).update_columns(status: "pending")
    post reject_admin_auction_path(auctions(:draft)), params: { reason: "ข้อมูลไม่ครบ" }
    assert auctions(:draft).reload.draft?
    assert_equal "ข้อมูลไม่ครบ", auctions(:draft).rejection_reason
  end

  test "sellers cannot approve" do
    sign_in_as users(:three)
    post approve_admin_auction_path(auctions(:pending))
    assert auctions(:pending).reload.pending?
  end

  test "cancel" do
    sign_in_as users(:one)
    post cancel_admin_auction_path(auctions(:live))
    assert auctions(:live).reload.cancelled?
  end
end
