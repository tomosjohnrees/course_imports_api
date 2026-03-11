require "test_helper"

class AccountDeletionFlowTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "flow-del-001",
      github_username: "flowuser",
      display_name: "Flow User",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_test_token"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "deleted user is logged out and cannot access protected pages" do
    sign_in_as(@user)

    delete account_path
    assert_redirected_to root_path

    get account_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]

    get dashboard_path
    assert_redirected_to root_path
  end

  test "deleted user can re-register and gets a fresh account" do
    sign_in_as(@user)

    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/reauth-owner/reauth-repo",
      github_owner: "reauth-owner",
      github_repo: "reauth-repo",
      title: "Old Course",
      status: "approved"
    )

    delete account_path

    assert_nil User.find_by(github_id: "flow-del-001")

    mock_omniauth_github(uid: "flow-del-001", nickname: "flowuser", name: "Flow User")
    get "/auth/github/callback"

    new_user = User.find_by(github_id: "flow-del-001")
    assert_not_nil new_user
    assert_not_equal @user.id, new_user.id
    assert_equal 0, new_user.courses.count
  end

  test "one user deleting account does not affect another user's data" do
    other_user = User.create!(
      github_id: "flow-del-other",
      github_username: "otheruser",
      display_name: "Other User",
      avatar_url: "https://example.com/other.png",
      github_token: "ghp_other_token"
    )
    other_course = Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/other-owner/other-repo",
      github_owner: "other-owner",
      github_repo: "other-repo",
      title: "Other Course",
      status: "approved"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/myowner/myrepo",
      github_owner: "myowner",
      github_repo: "myrepo",
      title: "My Course",
      status: "approved"
    )

    sign_in_as(@user)
    delete account_path

    assert_not_nil User.find_by(id: other_user.id)
    assert_not_nil Course.find_by(id: other_course.id)
  end
end
