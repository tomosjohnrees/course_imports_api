require "test_helper"

class CookieConsentLayoutTest < ActionDispatch::IntegrationTest
  test "cookie consent banner is present and hidden by default" do
    get root_path

    assert_select "div[data-cookie-consent-target='banner'].hidden"
    assert_select "button[data-action='cookie-consent#dismiss']", text: "Got it"
  end

  test "cookie consent and footer are present on authenticated pages" do
    user = User.create!(
      github_id: "consent001",
      github_username: "consenttester",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_consent_token"
    )
    sign_in_as(user)

    get dashboard_path

    assert_select "div[data-cookie-consent-target='banner']"
    assert_select "footer"
  end
end
