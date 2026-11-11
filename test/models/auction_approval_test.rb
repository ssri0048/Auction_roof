require "test_helper"

class AuctionApprovalTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup { @admin, @buyer, @seller = users(:one), users(:two), users(:three) }

  test "sellers submit for review; approvers publish directly" do
    a = auctions(:draft)
    a.submit_by(@seller)
    assert a.pending?
    a.submit_by(@admin)
    assert a.published?
    assert_equal @admin, a.approved_by
  end

  test "pending auctions cannot take bids and are not listed" do
    a = auctions(:pending)
    a.update_columns(starts_at: 1.hour.ago)
    assert_not a.place_bid(user: @buyer, amount: 99999).persisted?
    assert_not_includes Auction.visible, a
  end

  test "approve publishes, schedules closing and notifies the seller" do
    a = auctions(:pending)
    assert_enqueued_with(job: CloseAuctionJob) do
      assert a.approve!(@admin)
    end
    assert a.published?
    assert_equal @admin, a.approved_by
    assert_equal %w[approved], @seller.notifications.pluck(:kind)
  end

  test "cannot approve after the end time has passed" do
    a = auctions(:pending)
    a.update_columns(starts_at: 2.days.ago, ends_at: 1.day.ago)
    assert_not a.approve!(@admin)
    assert a.reload.pending?
  end

  test "reject returns to draft with the reason" do
    a = auctions(:pending)
    a.reject!("รูปไม่ชัด")
    assert a.draft?
    assert_equal "รูปไม่ชัด", a.rejection_reason
    assert_match "รูปไม่ชัด", @seller.notifications.last.message
  end
end
