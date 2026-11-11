require "test_helper"

class AuctionTypesTest < ActiveSupport::TestCase
  setup { @admin, @buyer, @seller = users(:one), users(:two), users(:three) }

  def finish(auction)
    auction.update_columns(ends_at: 1.second.ago)
    auction.close!
    auction.reload
  end

  test "first-price sealed: one bid each, price hidden, highest pays own bid" do
    a = auctions(:sealed_first)
    assert_not a.place_bid(user: @buyer, amount: 999).persisted?, "below reserve"
    assert a.place_bid(user: @buyer, amount: 1500).persisted?
    second = a.place_bid(user: @buyer, amount: 3000)
    assert_not second.persisted?
    assert_includes second.errors[:base], "การประมูลแบบยื่นซองเสนอราคาได้คนละ 1 ครั้งเท่านั้น"
    assert a.place_bid(user: @admin, amount: 1200).persisted?, "sealed bids may be lower than others"

    a.reload
    assert_nil a.current_price, "price is not stored while sealed"
    assert_not a.price_visible?
    assert_nil a.as_json[:current_price]
    assert_equal 0, Notification.where(kind: "outbid").count

    finish(a)
    assert_equal @buyer, a.winner
    assert_equal 1500, a.current_price
    assert a.price_visible?
  end

  test "second-price sealed: highest wins but pays the runner-up's bid" do
    a = auctions(:sealed_second)
    a.place_bid(user: @buyer, amount: 5000)
    a.place_bid(user: @admin, amount: 3200)
    finish(a)
    assert_equal @buyer, a.winner
    assert_equal 3200, a.current_price
  end

  test "second-price sealed with a single bid pays the reserve" do
    a = auctions(:sealed_second)
    a.place_bid(user: @buyer, amount: 5000)
    finish(a)
    assert_equal 1000, a.current_price
  end

  test "reverse: bids go down by the increment and the lowest wins" do
    a = auctions(:reverse)
    assert_equal 50000, a.maximum_bid
    assert_not a.place_bid(user: @buyer, amount: 50001).persisted?
    assert a.place_bid(user: @buyer, amount: 50000).persisted?
    assert_equal 49000, a.reload.maximum_bid
    assert_not a.place_bid(user: @admin, amount: 49500).persisted?
    assert_difference -> { @buyer.notifications.where(kind: "outbid").count } do
      assert a.place_bid(user: @admin, amount: 45000).persisted?
    end
    assert_match "ต่ำกว่าคุณ", @buyer.notifications.last.message
    finish(a)
    assert_equal @admin, a.winner
    assert_equal 45000, a.current_price
  end

  test "sealed auctions need no increment; open ones do" do
    a = Auction.new(seller: @seller, title: "x", auction_type: "first_price_sealed", starting_price: 10, min_increment: 5,
                    starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
    assert a.valid?
    assert_nil a.min_increment
    a.auction_type = "english"
    a.min_increment = nil
    assert_not a.valid?
  end

  test "unknown type is invalid" do
    a = auctions(:live)
    a.auction_type = "dutch"
    assert_not a.valid?
  end

  test "type cannot change after bids" do
    a = auctions(:live)
    a.place_bid(user: @buyer, amount: 10000)
    assert_not a.reload.update(auction_type: "reverse")
  end
end
