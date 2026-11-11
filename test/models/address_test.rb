require "test_helper"

class AddressTest < ActiveSupport::TestCase
  setup do
    province = Province.create!(code: "10", name_th: "กรุงเทพมหานคร")
    district = province.districts.create!(code: "1001", name_th: "พระนคร")
    @sub_district = district.sub_districts.create!(code: "100101", name_th: "พระบรมมหาราชวัง", postcode: "10200")
  end

  test "fills the postcode from the sub-district" do
    address = users(:one).addresses.create!(kind: :registered, house_no: "1", sub_district: @sub_district)

    assert_equal "10200", address.postcode
    assert_equal "กรุงเทพมหานคร", address.province.name_th
  end

  test "allows one address of each kind per user" do
    users(:one).addresses.create!(kind: :registered, house_no: "1", sub_district: @sub_district)
    duplicate = users(:one).addresses.build(kind: :registered, house_no: "2", sub_district: @sub_district)

    assert_not duplicate.valid?
    assert users(:one).addresses.build(kind: :contact, house_no: "2", sub_district: @sub_district).valid?
  end
end
