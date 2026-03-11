require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "acct-001",
      github_username: "accountuser",
      display_name: "Account User",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_test_token"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "show renders account page when signed in" do
    sign_in_as(@user)

    get account_path
    assert_response :success
    assert_select "h1", "Account"
  end

  test "show redirects to root when not signed in" do
    get account_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  test "destroy deletes the user and redirects" do
    sign_in_as(@user)

    assert_difference "User.count", -1 do
      delete account_path
    end

    assert_redirected_to root_path
    assert_equal "Your account has been deleted.", flash[:notice]
  end

  test "destroy clears the session" do
    sign_in_as(@user)
    assert session[:user_id].present?

    delete account_path
    assert_nil session[:user_id]
  end

  test "destroy redirects to root when not signed in" do
    delete account_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end
end
