require "test_helper"

class CourseSubmissionFlowTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "flow001",
      github_username: "flowuser",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_flow_token"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "full course submission flow from sign-in to show page" do
    sign_in_as(@user)
    follow_redirect!

    get new_course_path
    assert_response :success
    assert_select "h1", "Submit a Course"

    post courses_path, params: { course: { github_repo_url: "https://github.com/flowowner/flowrepo" } }
    course = Course.last
    assert_redirected_to course_path(course)
    follow_redirect!

    assert_response :success
    assert_select "h1", "Flowrepo"
    assert_select "a", text: /flowowner\/flowrepo/
    assert_select "span.bg-yellow-100", "Pending"
  end

  test "course submission with invalid URL shows errors and allows resubmission" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "not-a-url" } }
    assert_response :unprocessable_entity
    assert_select "div.bg-red-50"

    post courses_path, params: { course: { github_repo_url: "https://github.com/resubmit-owner/resubmit-repo" } }
    course = Course.last
    assert_redirected_to course_path(course)
    follow_redirect!

    assert_response :success
    assert_select "h1", "Resubmit Repo"
  end

  test "unauthenticated user is redirected then can view a course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/viewable-owner/viewable-repo",
      github_owner: "viewable-owner",
      github_repo: "viewable-repo",
      title: "Viewable Course",
      status: "approved"
    )

    get new_course_path
    assert_redirected_to root_path

    get course_path(course)
    assert_response :success
    assert_select "h1", "Viewable Course"
  end

  test "course owner can remove their course and is redirected to dashboard" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "https://github.com/removeable-owner/removeable-repo" } }
    course = Course.last
    follow_redirect!

    assert_select "button", "Remove Course"

    delete course_path(course)
    assert_redirected_to courses_path
    follow_redirect!

    assert_select "div.bg-green-50", /Course removed/
    assert_equal "removed", course.reload.status
  end

  test "navbar shows submit course link when signed in" do
    sign_in_as(@user)
    follow_redirect!

    get root_path
    assert_select "nav a[href='#{new_course_path}']", "Submit Course"
  end

  test "navbar hides submit course link when not signed in" do
    get root_path
    assert_select "nav a[href='#{new_course_path}']", count: 0
  end

  test "navbar shows my courses link when signed in" do
    sign_in_as(@user)
    follow_redirect!

    get root_path
    assert_select "nav a[href='#{courses_path}']", "My Courses"
  end

  test "navbar hides my courses link when not signed in" do
    get root_path
    assert_select "nav a[href='#{courses_path}']", count: 0
  end

  test "course dashboard flow from sign-in to index" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "https://github.com/dash-owner/dash-repo" } }
    Course.last

    get courses_path
    assert_response :success
    assert_select "h1", "My Courses"
    assert_select "a", text: "Dash Repo"
  end

  test "failed course resubmit flow" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/resub-flow/resub-flow-repo",
      github_owner: "resub-flow",
      github_repo: "resub-flow-repo",
      title: "Resub Flow Course",
      status: "failed",
      validation_error: "Repo not found"
    )
    sign_in_as(@user)

    get course_path(course)
    assert_response :success
    assert_select "button", text: "Resubmit for Validation"
    assert_select "p.text-red-700", "Repo not found"

    post resubmit_course_path(course)
    assert_redirected_to course_path(course)
    follow_redirect!

    assert_response :success
    assert_equal "Course resubmitted for validation.", flash[:notice]
  end

  test "submit and view on dashboard shows correct status" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "https://github.com/dashstatus-owner/dashstatus-repo" } }
    follow_redirect!
    assert_select "span.bg-yellow-100", text: "Pending"

    get courses_path
    assert_response :success
    assert_select "span.bg-yellow-100", text: "Pending"
    assert_select "p", text: "dashstatus-owner/dashstatus-repo"
  end
end
