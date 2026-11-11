require "test_helper"

class AuctionsControllerTest < ActionDispatch::IntegrationTest
  setup { @seller, @admin, @buyer = users(:three), users(:one), users(:two) }

  test "guests can browse tabs, the calendar and a live auction" do
    get auctions_path
    assert_response :success
    assert_select "h3", text: auctions(:live).title
    assert_select "h3", text: auctions(:draft).title, count: 0

    get auctions_path(tab: "upcoming")
    assert_select "h3", text: auctions(:upcoming).title

    get auctions_path(tab: "ended")
    assert_select "h3", text: auctions(:expired).title

    get calendar_auctions_path(month: auctions(:upcoming).starts_at.strftime("%Y-%m"))
    assert_response :success
    assert_select "a.cal__item", text: /#{auctions(:upcoming).title}/

    get auction_path(auctions(:live))
    assert_response :success
    assert_select "a", text: "เข้าสู่ระบบ"
  end

  test "search filters by title" do
    get auctions_path(q: "หม้อแปลง")
    assert_select "h3", text: auctions(:live).title
    get auctions_path(q: "ไม่มีจริง")
    assert_select ".empty-state"
  end

  test "drafts are hidden from other users" do
    get auction_path(auctions(:draft))
    assert_response :not_found
    sign_in_as @buyer
    get auction_path(auctions(:draft))
    assert_response :not_found
    sign_in_as @seller
    get auction_path(auctions(:draft))
    assert_response :success
  end

  test "mine tab requires login" do
    get auctions_path(tab: "mine")
    assert_redirected_to new_session_path
    sign_in_as @seller
    get auctions_path(tab: "mine")
    assert_select "h3", text: auctions(:draft).title
  end

  test "only create_auctions can open the new form" do
    sign_in_as @buyer
    get new_auction_path
    assert_redirected_to root_path
    sign_in_as @seller
    get new_auction_path
    assert_response :success
  end

  test "seller creates a draft, then submits it for approval" do
    sign_in_as @seller
    params = { auction: { title: "ครุภัณฑ์สำนักงาน", starting_price: "1500", min_increment: "100",
                          starts_at: 1.hour.from_now, ends_at: 2.days.from_now,
                          photos: [ fixture_file_upload("id_card.png", "image/png") ] } }
    assert_difference -> { Auction.count } do
      post auctions_path, params: params
    end
    auction = Auction.last
    assert auction.draft?
    assert_equal @seller, auction.seller
    assert auction.photos.attached?

    patch auction_path(auction), params: { publish: "1", auction: { title: "ครุภัณฑ์สำนักงาน ชุดใหญ่" } }
    assert_redirected_to auction_path(auction)
    assert auction.reload.pending?, "needs admin approval"
    assert_equal "ครุภัณฑ์สำนักงาน ชุดใหญ่", auction.title
  end

  test "seller picks the auction method; sealed needs no increment" do
    sign_in_as @seller
    post auctions_path, params: { publish: "1", auction: { title: "ยื่นซอง", auction_type: "second_price_sealed", starting_price: "500",
                                                          starts_at: 1.hour.from_now, ends_at: 2.days.from_now } }
    auction = Auction.last
    assert auction.second_price_sealed?
    assert auction.pending?
    assert_nil auction.min_increment
  end

  test "admin publishes directly" do
    sign_in_as @admin
    post auctions_path, params: { publish: "1", auction: { title: "ของแอดมิน", starting_price: "500", min_increment: "50",
                                                          starts_at: 1.hour.from_now, ends_at: 2.days.from_now } }
    assert Auction.last.published?
  end

  test "editing an approved auction sends it back for review" do
    sign_in_as @seller
    patch auction_path(auctions(:upcoming)), params: { auction: { title: "รถกระบะ (แก้ไข)" } }
    assert auctions(:upcoming).reload.pending?
  end

  test "sealed auction pages hide the price and bids until closed" do
    auction = auctions(:sealed_first)
    auction.place_bid(user: @buyer, amount: 7777)
    get auction_path(auction)
    assert_response :success
    assert_no_match "7,777", response.body
    assert_select ".price-box__price strong", text: "1 ซอง"

    sign_in_as @buyer
    get auction_path(auction)
    assert_select ".bid-box", text: /คุณยื่นซองเสนอราคาแล้ว/
    assert_select ".bid-form", count: 0
  end

  test "invalid auction re-renders the form" do
    sign_in_as @seller
    post auctions_path, params: { auction: { title: "", starting_price: "0", min_increment: "1", starts_at: 1.hour.from_now, ends_at: 1.minute.from_now } }
    assert_response :unprocessable_entity
    assert_select ".error-list li"
  end

  test "seller cannot edit a live auction or someone else's" do
    sign_in_as @seller
    get edit_auction_path(auctions(:live))
    assert_redirected_to auction_path(auctions(:live))

    other = Auction.create!(seller: @admin, title: "ของแอดมิน", starting_price: 1, min_increment: 1, starts_at: 1.day.from_now, ends_at: 2.days.from_now)
    patch auction_path(other), params: { auction: { title: "แฮก" } }
    assert_equal "ของแอดมิน", other.reload.title
  end

  test "seller can remove photos while editing" do
    auction = auctions(:draft)
    auction.photos.attach(fixture_file_upload("id_card.png", "image/png"))
    sign_in_as @seller
    perform_enqueued_jobs do
      patch auction_path(auction), params: { remove_photo_ids: [ auction.photos.first.id ], auction: { title: auction.title } }
    end
    assert_not auction.reload.photos.attached?
  end
end
