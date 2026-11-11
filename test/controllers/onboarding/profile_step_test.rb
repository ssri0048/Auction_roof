require "test_helper"

class Onboarding::ProfileStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:applicant)
    sign_in_as @user
  end

  def individual_params(**profile)
    { onboarding: {
      bidder_type: "individual", first_name: "สมชาย", last_name: "ใจดี", email_address: "somchai@example.com",
      profile_attributes: { title: "mr", national_id: "1-1017-00203-45-0", date_of_birth: "1990-05-01", **profile }
    } }
  end

  def juristic_params(**profile)
    { onboarding: {
      bidder_type: "juristic", first_name: "สมชาย", last_name: "ใจดี", email_address: "somchai@example.com",
      profile_attributes: {
        company_name_th: "บริษัท ตัวอย่าง จำกัด", tax_id: "0105556012341", company_type: "company_limited",
        company_registered_on: "2015-01-01", vat_registered: "1", vat_branch_code: "00000",
        authorized_person_name: "สมหญิง ใจดี", authorized_person_national_id: "1101700203450",
        authorized_person_position: "กรรมการผู้จัดการ", **profile
      }
    } }
  end

  test "pre-fills the name from registration" do
    get onboarding_step_path("profile")

    assert_response :success
    assert_select "input[name='onboarding[first_name]'][value=?]", "Applicant"
  end

  test "saves an individual profile and updates the account" do
    patch onboarding_step_path("profile"), params: individual_params

    assert_redirected_to onboarding_step_path("finance")
    @user.reload
    assert @user.individual?
    assert_equal "สมชาย", @user.first_name
    assert_equal "somchai@example.com", @user.email_address
    assert_equal "1101700203450", @user.profile.national_id
  end

  test "rejects a bad national ID, under-20s and a missing email" do
    params = individual_params(national_id: "1101700203451", date_of_birth: 19.years.ago.to_date.to_s)
    params[:onboarding][:email_address] = ""

    patch onboarding_step_path("profile"), params: params

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /เลขบัตรประชาชน ไม่ถูกต้อง/
    assert_select ".flash--alert li", /อายุอย่างน้อย 20 ปี/
    assert_select ".flash--alert li", /อีเมล ต้องระบุ/
    assert_equal 0, @user.reload.onboarding_step
  end

  test "rejects a national ID already used by someone else" do
    users(:one).create_profile!(national_id: "1101700203450")

    patch onboarding_step_path("profile"), params: individual_params

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /ถูกใช้ลงทะเบียนแล้ว/
  end

  test "saves a juristic profile" do
    patch onboarding_step_path("profile"), params: juristic_params

    assert_redirected_to onboarding_step_path("finance")
    profile = @user.reload.profile
    assert @user.juristic?
    assert_equal "0105556012341", profile.tax_id
    assert profile.vat_registered?
  end

  test "requires a 5-digit branch code when VAT registered" do
    patch onboarding_step_path("profile"), params: juristic_params(vat_branch_code: "")

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /รหัสสาขา ต้องเป็นตัวเลข 5 หลัก/
  end

  test "switching bidder type clears the other type's fields" do
    patch onboarding_step_path("profile"), params: juristic_params
    patch onboarding_step_path("profile"), params: individual_params

    profile = @user.reload.profile
    assert @user.individual?
    assert_nil profile.tax_id
    assert_nil profile.company_name_th
    assert_not profile.vat_registered?
  end

  test "requires choosing a bidder type" do
    params = individual_params
    params[:onboarding].delete(:bidder_type)

    patch onboarding_step_path("profile"), params: params

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /กรุณาเลือกประเภทผู้ประมูล/
  end
end
