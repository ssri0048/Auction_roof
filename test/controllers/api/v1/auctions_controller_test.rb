require "test_helper"

class Api::V1::AuctionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/auctions lists live auctions" do
    get api_v1_auctions_path, as: :json
    assert_response :success
    ids = response.parsed_body["auctions"].map { it["id"] }
    assert_includes ids, auctions(:live).id
    assert_not_includes ids, auctions(:draft).id
  end

  test "GET /api/v1/auctions?tab=upcoming" do
    get api_v1_auctions_path(tab: "upcoming"), as: :json
    assert_equal [ auctions(:upcoming).id ], response.parsed_body["auctions"].map { it["id"] }
  end

  test "GET /api/v1/auctions/:id includes bids; drafts are 404" do
    get api_v1_auction_path(auctions(:expired)), as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal "5200.0", body["current_price"]
    assert_equal [ "5200.0", "5000.0" ], body["bids"].map { it["amount"] }

    get api_v1_auction_path(auctions(:draft)), as: :json
    assert_response :not_found
  end

  test "sealed auctions hide price and bids in the API until closed" do
    auction = auctions(:sealed_first)
    auction.place_bid(user: users(:two), amount: 4321)
    get api_v1_auction_path(auction), as: :json
    body = response.parsed_body
    assert_equal "first_price_sealed", body["auction_type"]
    assert_nil body["current_price"]
    assert_empty body["bids"]
    assert_no_match "4321", response.body
  end

  test "POST bids: 401 / 403 / 422 / 201" do
    auction = auctions(:live)
    post api_v1_auction_bids_path(auction), params: { bid: { amount: 10000 } }, as: :json
    assert_response :unauthorized

    post api_v1_session_path, params: { username: "two", password: "password" }, as: :json
    post api_v1_auction_bids_path(auction), params: { bid: { amount: 1 } }, as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].key?("amount")

    post api_v1_auction_bids_path(auction), params: { bid: { amount: 10000 } }, as: :json
    assert_response :created
    assert_equal "10500.0", response.parsed_body["auction"]["minimum_bid"]

    users(:two).role.update!(permissions: [])
    post api_v1_auction_bids_path(auction), params: { bid: { amount: 20000 } }, as: :json
    assert_response :forbidden
  end
end
