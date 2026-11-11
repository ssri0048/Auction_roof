require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
    assert_select "h1"
  end

  test "has the dark mode toggle and applies the saved theme early" do
    get root_url
    assert_select "button.theme-toggle[data-controller=theme]"
    assert_select "head script", text: /localStorage.getItem\("theme"\)/
  end
end

class HomeControllerSignedInTest < ActionDispatch::IntegrationTest
  test "shows login and register links when signed out" do
    get root_url
    assert_select ".nav-links a[href=?]", new_session_path
    assert_select "a[href=?]", new_registration_path
  end

  test "shows the user's name and logout when signed in" do
    sign_in_as(users(:one))
    get root_url
    assert_select ".nav-user", /One/
    assert_select "form[action=?] button", session_path, text: "ออกจากระบบ"
  end

  test "shows flash messages on the landing page" do
    sign_in_as(users(:one))
    get onboarding_path # staff have no onboarding, so this redirects home with a notice
    follow_redirect!
    assert_select ".landing-flash .flash--notice", "ไม่มีข้อมูลที่ต้องกรอกเพิ่ม"
  end
end
