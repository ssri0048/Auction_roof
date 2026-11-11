require "test_helper"

class ThaiIdValidatorTest < ActiveSupport::TestCase
  test "checks length, digits and the check digit" do
    assert ThaiIdValidator.valid?("1101700203450")
    assert_not ThaiIdValidator.valid?("1101700203451"), "wrong check digit"
    assert_not ThaiIdValidator.valid?("110170020345"), "12 digits"
    assert_not ThaiIdValidator.valid?("11017002034a0")
  end
end
