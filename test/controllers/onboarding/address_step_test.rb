require "test_helper"

class Onboarding::AddressStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:applicant)
    complete_profile_step(@user)
    complete_finance_step(@user)
    @sub_district = sample_sub_district
    sign_in_as @user
  end

  def address(**overrides)
    { house_no: "99/1", moo: "", soi: "สุขุมวิท 1", road: "", sub_district_id: @sub_district.id, **overrides }
  end

  test "saves the registered address only when the others are the same" do
    patch onboarding_step_path("address"), params: { onboarding: { registered: address, contact_same: "1", tax_invoice_same: "1" } }

    assert_redirected_to onboarding_step_path("documents")
    registered = @user.addresses.sole
    assert registered.registered?
    assert_equal "10200", registered.postcode
    assert_nil registered.moo
  end

  test "saves a separate contact address" do
    patch onboarding_step_path("address"), params: { onboarding: {
      registered: address, contact_same: "0", contact: address(house_no: "5"), tax_invoice_same: "1"
    } }

    assert_redirected_to onboarding_step_path("documents")
    assert_equal "5", @user.addresses.contact.sole.house_no

    patch onboarding_step_path("address"), params: { onboarding: { registered: address, contact_same: "1", tax_invoice_same: "1" } }
    assert_empty @user.addresses.contact, "ticking 'same' again removes the separate address"
  end

  test "shows which address is incomplete" do
    patch onboarding_step_path("address"), params: { onboarding: {
      registered: address(house_no: ""), contact_same: "0", contact: address(sub_district_id: ""), tax_invoice_same: "1"
    } }

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /ที่อยู่ตามทะเบียน: บ้านเลขที่ ต้องระบุ/
    assert_select ".flash--alert li", /ที่อยู่ติดต่อ: ตำบล \/ แขวง ต้องเลือก/
  end

  test "re-shows the chosen province and district" do
    @user.addresses.create!(kind: :registered, house_no: "1", sub_district: @sub_district)

    get onboarding_step_path("address")

    assert_select "select[name='onboarding[registered][selected_province_id]'] option[selected][value=?]", @sub_district.province.id.to_s
    assert_select "select[name='onboarding[registered][sub_district_id]'] option[selected][data-postcode=?]", "10200"
  end
end
