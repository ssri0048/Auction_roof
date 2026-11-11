require "test_helper"

class UserProfileTest < ActiveSupport::TestCase
  setup { @profile = users(:one).create_profile!(national_id: "1-1017-00203-45-1", passport_no: "aa 1234567") }

  test "encrypts the national ID and passport at rest" do
    raw = UserProfile.connection.select_one("SELECT national_id, passport_no FROM user_profiles WHERE id = #{@profile.id}")

    assert_not_includes raw["national_id"], "1101700203451"
    assert_not_includes raw["passport_no"], "AA1234567"
    assert_equal "1101700203451", @profile.reload.national_id
    assert_equal "AA1234567", @profile.passport_no
  end

  test "can be found by national ID and rejects duplicates" do
    assert_equal @profile, UserProfile.find_by(national_id: "1101700203451")

    duplicate = users(:two).build_profile(national_id: "1101700203451")
    assert_not duplicate.valid?
    assert duplicate.errors.added?(:national_id, :taken, value: "1101700203451")
  end

  test "masks sensitive numbers" do
    assert_equal "x-xxxx-xxxxx-45-1", @profile.masked_national_id
    assert_equal "xxxxxx567", @profile.masked_passport_no
    assert_nil UserProfile.new.masked_tax_id
  end
end
