require "test_helper"

class Onboarding::DocumentsStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:applicant)
    complete_profile_step(@user)
    complete_finance_step(@user)
    complete_address_step(@user)
    sign_in_as @user
  end

  def image = fixture_file_upload("id_card.png", "image/png")

  test "individuals upload the ID card and a selfie" do
    patch onboarding_step_path("documents"), params: { onboarding: { id_card_front: image, selfie_with_id: image } }

    assert_redirected_to onboarding_step_path("bank")
    assert @user.reload.profile.id_card_front.attached?
  end

  test "an empty file field keeps the file already uploaded" do
    patch onboarding_step_path("documents"), params: { onboarding: { id_card_front: image, selfie_with_id: image } }
    patch onboarding_step_path("documents"), params: { onboarding: { id_card_front: "", selfie_with_id: "", supporting_documents: [ "" ] } }

    assert_redirected_to onboarding_step_path("bank")
    assert @user.reload.profile.selfie_with_id.attached?
  end

  test "requires both individual documents and checks the file type" do
    text = fixture_file_upload("evil.txt", "text/plain")
    patch onboarding_step_path("documents"), params: { onboarding: { id_card_front: text } }

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /รูปถ่ายคู่กับบัตรประชาชน ต้องอัปโหลด/
    assert_select ".flash--alert li", /บัตรประชาชน \(ด้านหน้า\) ต้องเป็นไฟล์รูปภาพ/
  end

  test "juristic bidders need a recent affidavit, ภ.พ.20 when VAT registered and a power of attorney for agents" do
    @user.update!(bidder_type: "juristic")
    @user.profile.update!(vat_registered: true, vat_branch_code: "00000")

    patch onboarding_step_path("documents"), params: { onboarding: {
      company_affidavit: image, company_affidavit_issued_on: 7.months.ago.to_date, authorized_person_id_card: image,
      account_user_is_authorized_person: "0"
    } }

    assert_response :unprocessable_entity
    assert_select ".flash--alert li", /ต้องออกให้ไม่เกิน 6 เดือน/
    assert_select ".flash--alert li", /ภ.พ.20 ต้องอัปโหลด/
    assert_select ".flash--alert li", /หนังสือมอบอำนาจ ต้องอัปโหลด/

    # Nothing was saved, so the files are sent again.
    patch onboarding_step_path("documents"), params: { onboarding: {
      company_affidavit: image, company_affidavit_issued_on: 1.month.ago.to_date, authorized_person_id_card: image,
      vat_certificate: image, account_user_is_authorized_person: "0",
      power_of_attorney: image, attorney_id_card: image
    } }
    assert_redirected_to onboarding_step_path("bank")
  end
end
