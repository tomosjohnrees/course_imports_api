require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "full sign-in flow from home page" do
    get root_path
    assert_response :success
    assert_select "form[action='/auth/github']"

    mock_omniauth_github(uid: "60001", nickname: "flowuser", image: "https://example.com/avatar.png")
    get "/auth/github/callback"
    assert_redirected_to root_path
    follow_redirect!

    assert_select "nav span", "flowuser"
    assert_select "nav img[src='https://example.com/avatar.png']"
    assert_select "nav form[action='/auth/github']", count: 0
  end

  test "full sign-out flow" do
    user = User.create!(
      github_id: "60002",
      github_username: "signoutflow",
      avatar_url: "https://example.com/avatar.png"
    )
    sign_in_as(user)
    follow_redirect!

    get root_path
    assert_select "nav span", "signoutflow"

    delete "/sign_out"
    assert_redirected_to root_path
    follow_redirect!

    assert_select "nav form[action='/auth/github']"
    assert_select "nav span", { text: "signoutflow", count: 0 }
    assert_select "div.bg-green-50", text: /Signed out/
  end

  test "banned user sees alert flash on sign-in attempt" do
    User.create!(github_id: "60004", github_username: "bannedflow", banned: true)
    mock_omniauth_github(uid: "60004", nickname: "bannedflow")

    get "/auth/github/callback"
    assert_redirected_to root_path
    follow_redirect!

    assert_select "div.bg-red-50", text: /suspended/
    assert_select "nav form[action='/auth/github']"
  end

  test "sign-in button uses POST method for CSRF protection" do
    get root_path
    assert_select "nav form[action='/auth/github'][method='post']"
    assert_select ".max-w-2xl form[action='/auth/github'][method='post']"
  end

  test "home page does not expose sensitive data in HTML" do
    user = User.create!(
      github_id: "60005",
      github_username: "secureuser",
      github_token: "ghp_supersecret_token",
      avatar_url: "https://example.com/avatar.png"
    )
    sign_in_as(user)
    follow_redirect!

    get root_path
    assert_no_match(/ghp_supersecret_token/, response.body)
    assert_no_match(/60005/, response.body)
  end
end
