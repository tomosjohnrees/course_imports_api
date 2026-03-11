require "test_helper"

class MetaTagsAndLayoutTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "meta001",
      github_username: "metatester",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_meta_token"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  # --- <title> tag ---

  test "home page has default title" do
    get root_path
    assert_select "title", text: /Course Imports — Community Course Registry/
  end

  test "course show page has course title in title tag" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/meta-owner/meta-repo",
      github_owner: "meta-owner",
      github_repo: "meta-repo",
      title: "Learn Testing",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_select "title", text: /Learn Testing — Course Imports/
  end

  test "dashboard has My Courses in title" do
    sign_in_as(@user)

    get dashboard_path
    assert_select "title", text: /My Courses — Course Imports/
  end

  # --- <meta name="description"> ---

  test "home page has meta description" do
    get root_path
    assert_select "meta[name='description'][content]"
    assert_select "meta[name='description']" do |elements|
      content = elements.first["content"]
      assert_match(/community/, content.downcase)
    end
  end

  test "course show page has meta description with course description" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/meta-desc/desc-repo",
      github_owner: "meta-desc",
      github_repo: "desc-repo",
      title: "Described Course",
      description: "A wonderful course about testing Rails applications",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_select "meta[name='description']" do |elements|
      content = elements.first["content"]
      assert_match(/wonderful course about testing/, content)
    end
  end

  test "course show page has fallback meta description when course has no description" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/meta-nodesc/nodesc-repo",
      github_owner: "meta-nodesc",
      github_repo: "nodesc-repo",
      title: "No Description Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_select "meta[name='description']" do |elements|
      content = elements.first["content"]
      assert_match(/Course Imports/, content)
    end
  end

  test "course show page truncates long descriptions in meta tag" do
    long_description = "A" * 300
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/meta-long/long-repo",
      github_owner: "meta-long",
      github_repo: "long-repo",
      title: "Long Description Course",
      description: long_description,
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_select "meta[name='description']" do |elements|
      content = elements.first["content"]
      assert content.length <= 160, "Meta description should be truncated to 160 characters, got #{content.length}"
    end
  end

  # --- application-name meta tag ---

  test "application-name meta tag says Course Imports" do
    get root_path
    assert_select "meta[name='application-name'][content='Course Imports']"
  end

  # --- responsive navbar ---

  test "navbar has stimulus dropdown controller when signed in" do
    sign_in_as(@user)

    get root_path
    assert_select "div[data-controller='dropdown']"
  end

  test "navbar dropdown contains username and sign out" do
    sign_in_as(@user)

    get root_path
    assert_select "div[data-dropdown-target='menu']" do
      assert_select "span", text: "metatester"
      assert_select "button", text: /Sign out/
    end
  end

  test "navbar shows my courses link when signed in" do
    sign_in_as(@user)

    get root_path
    assert_select "nav a[href='#{dashboard_path}']", text: "My Courses"
  end

  test "navbar shows sign-in button when not authenticated" do
    get root_path
    assert_select "nav form[action='/auth/github']" do
      assert_select "button", text: /Sign in with GitHub/
    end
  end

  # --- lazy loading on avatars ---

  test "navbar avatar uses lazy loading when signed in" do
    sign_in_as(@user)

    get root_path
    assert_select "nav img[loading='lazy']"
  end

  # --- meta description does not leak user-generated XSS ---

  test "course meta description escapes HTML in course description" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/meta-xss/xss-repo",
      github_owner: "meta-xss",
      github_repo: "xss-repo",
      title: "XSS Test Course",
      description: '<script>alert("xss")</script>',
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_no_match(/<script>alert/, response.body)
  end
end
