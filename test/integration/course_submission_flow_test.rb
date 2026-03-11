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
    assert_select "span.bg-mustard-light", "Pending"
  end

  test "course submission with invalid URL shows errors and allows resubmission" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "not-a-url" } }
    assert_response :unprocessable_entity
    assert_select "div.bg-rose-light"

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
    assert_redirected_to dashboard_path
    follow_redirect!

    assert_select "div.bg-sage-light", /Course removed/
    assert_equal "removed", course.reload.status
  end

  test "navbar shows my courses link when signed in" do
    sign_in_as(@user)
    follow_redirect!

    get root_path
    assert_select "nav a[href='#{dashboard_path}']", "My Courses"
  end

  test "navbar shows sign-in button when not signed in" do
    get root_path
    assert_select "nav form[action='/auth/github']" do
      assert_select "button", text: /Sign in with GitHub/
    end
  end

  test "navbar hides my courses link when not signed in" do
    get root_path
    assert_select "nav a[href='#{dashboard_path}']", count: 0
  end

  test "course dashboard flow from sign-in to dashboard" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "https://github.com/dash-owner/dash-repo" } }
    Course.last

    get dashboard_path
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
    assert_select "p.text-terracotta", "Repo not found"

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
    assert_select "span.bg-mustard-light", text: "Pending"

    get dashboard_path
    assert_response :success
    assert_select "span.bg-mustard-light", text: "Pending"
    assert_select "p", text: "dashstatus-owner/dashstatus-repo"
  end

  test "search flow finds approved course and shows no results for unmatched query" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/flow-srch/elixir-course",
      github_owner: "flow-srch",
      github_repo: "elixir-course",
      title: "Elixir Programming",
      description: "Functional programming with Elixir and OTP",
      status: "approved"
    )

    get courses_path
    assert_response :success
    assert_select "input[name='q']"

    get courses_path, params: { q: "elixir" }
    assert_response :success
    assert_select "a", text: "Elixir Programming"
    assert_select "input[name='q'][value='elixir']"

    get courses_path, params: { q: "nonexistentxyzterm" }
    assert_response :success
    assert_select "p", /No courses found for/
    assert_select "a", text: "Clear filters"
  end
end
