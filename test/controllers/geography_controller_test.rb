require "test_helper"

class GeographyControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sub_district = sample_sub_district
    sign_in_as users(:applicant)
  end

  test "lists districts of a province and sub-districts with postcodes" do
    get geography_districts_path(province_id: @sub_district.province.id)
    assert_equal [ "พระนคร" ], response.parsed_body.pluck("name")

    get geography_sub_districts_path(district_id: @sub_district.district_id)
    assert_includes response.parsed_body, { "id" => @sub_district.id, "name" => "พระบรมมหาราชวัง", "postcode" => "10200" }
  end
end
