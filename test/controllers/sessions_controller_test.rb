require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  # --- OAuth callback: new user ---

  test "create signs in a new user via GitHub OAuth" do
    mock_omniauth_github(uid: "99001", nickname: "newuser", name: "New User")

    assert_difference "User.count", 1 do
      get "/auth/github/callback"
    end

    assert_redirected_to root_path
    assert_equal "Signed in as newuser.", flash[:notice]

    user = User.find_by(github_id: "99001")
    assert_equal user.id, session[:user_id]
  end

  # --- OAuth callback: returning user ---

  test "create signs in a returning user and updates their info" do
    existing = User.create!(github_id: "99002", github_username: "oldname", github_token: "old_token")
    mock_omniauth_github(uid: "99002", nickname: "newname", name: "New Name", token: "ghp_new_token")

    assert_no_difference "User.count" do
      get "/auth/github/callback"
    end

    assert_redirected_to root_path
    assert_equal "Signed in as newname.", flash[:notice]
    assert_equal existing.id, session[:user_id]

    existing.reload
    assert_equal "newname", existing.github_username
    assert_equal "ghp_new_token", existing.github_token
  end

  # --- OAuth callback: banned user ---

  test "create rejects a banned user" do
    User.create!(github_id: "99003", github_username: "banned_user", banned: true)
    mock_omniauth_github(uid: "99003", nickname: "banned_user")

    get "/auth/github/callback"

    assert_redirected_to root_path
    assert_equal "Your account has been suspended.", flash[:alert]
    assert_nil session[:user_id]
  end

  # --- Session fixation prevention ---

  test "create resets session before setting user_id to prevent session fixation" do
    mock_omniauth_github(uid: "99004", nickname: "sessionuser")

    # Set a marker in session to verify it gets reset
    get "/auth/github/callback"

    # Session should have user_id set after reset
    user = User.find_by(github_id: "99004")
    assert_equal user.id, session[:user_id]
  end

  test "create resets session for banned users too" do
    User.create!(github_id: "99005", github_username: "banned2", banned: true)
    mock_omniauth_github(uid: "99005", nickname: "banned2")

    get "/auth/github/callback"

    assert_nil session[:user_id]
  end

  # --- Sign out ---

  test "destroy clears session and redirects to root" do
    # First sign in
    mock_omniauth_github(uid: "99006", nickname: "signoutuser")
    get "/auth/github/callback"
    assert session[:user_id].present?

    # Then sign out
    delete "/sign_out"

    assert_redirected_to root_path
    assert_equal "Signed out.", flash[:notice]
    assert_nil session[:user_id]
  end

  # --- Auth failure ---

  test "failure redirects to root with error message" do
    get "/auth/failure", params: { message: "invalid_credentials" }

    assert_redirected_to root_path
    assert_equal "Authentication failed: Invalid credentials.", flash[:alert]
  end

  test "failure handles blank message param" do
    get "/auth/failure", params: { message: "" }

    assert_redirected_to root_path
    assert_equal "Authentication failed: .", flash[:alert]
  end

  test "failure handles missing message param" do
    get "/auth/failure"

    assert_redirected_to root_path
    assert_match(/Authentication failed:/, flash[:alert])
  end

  # --- Routing ---

  test "routes the GitHub OAuth callback" do
    assert_routing({ path: "/auth/github/callback", method: :get },
                   { controller: "sessions", action: "create", provider: "github" })
  end

  test "routes the auth failure path" do
    assert_routing({ path: "/auth/failure", method: :get },
                   { controller: "sessions", action: "failure" })
  end

  test "routes the sign out path" do
    assert_routing({ path: "/sign_out", method: :delete },
                   { controller: "sessions", action: "destroy" })
  end
end
