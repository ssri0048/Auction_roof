require "test_helper"

class ThaiGeographyTest < ActiveSupport::TestCase
  test "imports provinces, districts and sub-districts and can run again" do
    2.times { ThaiGeography.import!(file_fixture("thai_geography_sample.json")) }

    assert_equal 1, Province.count
    sub_district = SubDistrict.find_by!(code: "100102")
    assert_equal "10200", sub_district.postcode
    assert_equal "กรุงเทพมหานคร", sub_district.province.name_th
  end

  test "the bundled data covers the whole country" do
    provinces = JSON.parse(File.read(ThaiGeography::DATA_PATH))["provinces"]

    assert_equal 77, provinces.size
    assert provinces.all? { |p| p["districts"].any? && p["districts"].all? { |d| d["sub_districts"].all? { it["postcode"].match?(/\A\d{5}\z/) } } }
  end
end
