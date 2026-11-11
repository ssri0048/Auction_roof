require "test_helper"

class BidsControllerTest < ActionDispatch::IntegrationTest
  setup { @auction = auctions(:live) }

  test "requires login" do
    post auction_bids_path(@auction), params: { bid: { amount: 10000 } }
    assert_redirected_to new_session_path
  end

  test "buyer places a bid and the price is broadcast" do
    sign_in_as users(:two)
    assert_turbo_stream_broadcasts @auction, count: 2 do
      post auction_bids_path(@auction), params: { bid: { amount: 10000 } }
    end
    assert_redirected_to auction_path(@auction)
    assert_equal 10000, @auction.reload.current_price
  end

  test "too-low bid shows the error" do
    sign_in_as users(:two)
    post auction_bids_path(@auction), params: { bid: { amount: 1 } }
    assert_redirected_to auction_path(@auction)
    assert_match "ต้องไม่ต่ำกว่า 10,000 บาท", flash[:alert]
    assert_equal 0, @auction.reload.bids_count
  end

  test "users without place_bids are turned away" do
    users(:two).role.update!(permissions: [])
    sign_in_as users(:two)
    post auction_bids_path(@auction), params: { bid: { amount: 10000 } }
    assert_redirected_to root_path
  end

  test "bidders must pass onboarding review first" do
    sign_in_as users(:applicant)
    post auction_bids_path(@auction), params: { bid: { amount: 10000 } }

    assert_redirected_to onboarding_path
    assert_equal "ต้องยืนยันตัวตนให้ผ่านก่อนจึงจะเสนอราคาได้", flash[:alert]
    assert_equal 0, @auction.reload.bids_count
  end

  test "bids above the approved bid limit are rejected" do
    users(:two).update!(bid_limit: 15000)
    sign_in_as users(:two)
    post auction_bids_path(@auction), params: { bid: { amount: 20000 } }

    assert_match "เกินวงเงินประมูลของคุณ (15,000 บาท)", flash[:alert]
    assert_equal 0, @auction.reload.bids_count
  end
end
