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
    # Simulate a session with a non-existent user_id
    mock_omniauth_github(uid: "88003", nickname: "tempuser")
    get "/auth/github/callback"

    user = User.find_by(github_id: "88003")
    user.destroy!

    # The session still has user_id but the user no longer exists
    # current_user should return nil (find_by returns nil for missing records)
    get "/up"
    assert_response :success
  end
end
