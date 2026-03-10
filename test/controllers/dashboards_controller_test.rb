require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "cc001",
      github_username: "courseuser",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_test_token"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "dashboard lists current users courses when signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-owner/dash-repo",
      github_owner: "dash-owner",
      github_repo: "dash-repo",
      title: "My Listed Course",
      status: "approved"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "h1", "My Courses"
    assert_select "a", text: "My Listed Course"
  end

  test "dashboard does not show other users courses" do
    other_user = User.create!(github_id: "cc_other_dash", github_username: "otherdash", avatar_url: "https://example.com/other.png")
    Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/other-dash/other-dash-repo",
      github_owner: "other-dash",
      github_repo: "other-dash-repo",
      title: "Others Course",
      status: "approved"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "a", { text: "Others Course", count: 0 }
  end

  test "dashboard redirects to root when not signed in" do
    get dashboard_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  test "dashboard shows empty state when user has no courses" do
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "p", /You haven't submitted any courses yet/
    assert_select "a", text: "Submit your first course"
  end

  test "dashboard shows status badges for each course" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-badge/pending-repo",
      github_owner: "dash-badge",
      github_repo: "pending-repo",
      title: "Pending Course",
      status: "pending"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-badge/approved-repo",
      github_owner: "dash-badge",
      github_repo: "approved-repo",
      title: "Approved Course",
      status: "approved"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "span.bg-yellow-100", text: "Pending"
    assert_select "span.bg-green-100", text: "Approved"
  end

  test "dashboard shows remove button for non-removed courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-rm/active-repo",
      github_owner: "dash-rm",
      github_repo: "active-repo",
      title: "Active Course",
      status: "approved"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "button", text: "Remove"
  end

  test "dashboard hides remove button for removed courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-rm/removed-repo",
      github_owner: "dash-rm",
      github_repo: "removed-repo",
      title: "Removed Course",
      status: "removed"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "button", { text: "Remove", count: 0 }
  end

  test "dashboard displays github owner and repo for each course" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-meta/meta-repo",
      github_owner: "dash-meta",
      github_repo: "meta-repo",
      title: "Meta Course",
      status: "approved"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "p", text: "dash-meta/meta-repo"
  end

  test "dashboard orders courses by most recent first" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-order/old-repo",
      github_owner: "dash-order",
      github_repo: "old-repo",
      title: "Old Course",
      status: "approved",
      created_at: 2.days.ago
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-order/new-repo",
      github_owner: "dash-order",
      github_repo: "new-repo",
      title: "New Course",
      status: "approved",
      created_at: 1.hour.ago
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    response_body = @response.body
    new_pos = response_body.index("New Course")
    old_pos = response_body.index("Old Course")
    assert new_pos < old_pos, "New course should appear before old course"
  end

  test "dashboard includes submit course link" do
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "a[href='#{new_course_path}']", text: "Submit Course"
  end

  test "dashboard shows all statuses including pending and failed" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-all/pending-repo",
      github_owner: "dash-all",
      github_repo: "pending-repo",
      title: "My Pending",
      status: "pending"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dash-all/failed-repo",
      github_owner: "dash-all",
      github_repo: "failed-repo",
      title: "My Failed",
      status: "failed",
      validation_error: "Some error"
    )
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "a", text: "My Pending"
    assert_select "a", text: "My Failed"
  end

  test "routes GET /dashboard to dashboards#show" do
    assert_routing({ path: "/dashboard", method: :get },
                   { controller: "dashboards", action: "show" })
  end
end
