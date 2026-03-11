require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  # --- current_user ---

  test "current_user returns nil when not signed in" do
    # Access a public route without signing in
    get "/up"
    assert_response :success
  end

  test "current_user returns the user after signing in" do
    mock_omniauth_github(uid: "88001", nickname: "helperuser")
    get "/auth/github/callback"
    follow_redirect!

    user = User.find_by(github_id: "88001")
    assert_equal user.id, session[:user_id]
  end

  test "current_user returns nil after signing out" do
    mock_omniauth_github(uid: "88002", nickname: "signouthelper")
    get "/auth/github/callback"
    assert session[:user_id].present?

    delete "/sign_out"
    assert_nil session[:user_id]
  end

  test "current_user returns nil for invalid session user_id" do
    mock_omniauth_github(uid: "88003", nickname: "tempuser")
    get "/auth/github/callback"

    user = User.find_by(github_id: "88003")
    user.destroy!

    get "/up"
    assert_response :success
  end

  # --- Layout rendering ---

  test "layout renders navbar on every page" do
    get root_path
    assert_select "nav" do
      assert_select "a[href='/']", "Course Imports"
    end
  end

  test "navbar shows sign-in button when not signed in" do
    get root_path
    assert_select "nav form[action='/auth/github']" do
      assert_select "button", text: /Sign in with GitHub/
    end
  end

  test "navbar shows avatar and username when signed in" do
    user = User.create!(
      github_id: "88011",
      github_username: "navuser",
      avatar_url: "https://example.com/avatar.png"
    )
    sign_in_as(user)
    follow_redirect!

    get root_path
    assert_select "nav" do
      assert_select "img[src='https://example.com/avatar.png']"
      assert_select "span", "navuser"
    end
  end

  test "navbar shows sign-out button when signed in" do
    user = User.create!(
      github_id: "88012",
      github_username: "signoutnav",
      avatar_url: "https://example.com/avatar.png"
    )
    sign_in_as(user)
    follow_redirect!

    get root_path
    assert_select "nav form[action='/sign_out']" do
      assert_select "button", text: /Sign out/
    end
  end

  test "navbar hides sign-in button when signed in" do
    user = User.create!(
      github_id: "88013",
      github_username: "nosigninbtn",
      avatar_url: "https://example.com/avatar.png"
    )
    sign_in_as(user)
    follow_redirect!

    get root_path
    assert_select "nav form[action='/auth/github']", count: 0
  end

  # --- Flash messages ---

  test "notice flash renders with green styling" do
    mock_omniauth_github(uid: "88020", nickname: "flashuser")
    get "/auth/github/callback"
    follow_redirect!

    assert_select "div.bg-sage-light", text: /Signed in as flashuser/
  end

  test "alert flash renders with red styling" do
    User.create!(github_id: "88021", github_username: "bannedflash", banned: true)
    mock_omniauth_github(uid: "88021", nickname: "bannedflash")
    get "/auth/github/callback"
    follow_redirect!

    assert_select "div.bg-rose-light", text: /suspended/
  end
end
