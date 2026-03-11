require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
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

  # --- new action ---

  test "new renders the submission form when signed in" do
    sign_in_as(@user)

    get new_course_path
    assert_response :success
    assert_select "h1", "Submit a Course"
    assert_select "form" do
      assert_select "input[name='course[github_repo_url]']"
      assert_select "input[type='submit'][value='Submit Course']"
    end
  end

  test "new redirects to root when not signed in" do
    get new_course_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- create action ---

  test "create saves a course and redirects to show" do
    sign_in_as(@user)

    assert_difference "Course.count", 1 do
      post courses_path, params: { course: { github_repo_url: "https://github.com/testowner/testrepo" } }
    end

    course = Course.last
    assert_equal "testowner", course.github_owner
    assert_equal "testrepo", course.github_repo
    assert_equal "https://github.com/testowner/testrepo", course.github_repo_url
    assert_equal "Testrepo", course.title
    assert_equal "pending", course.status
    assert_equal @user.id, course.user_id

    assert_redirected_to course_path(course.github_owner, course.github_repo)
    assert_equal "Course submitted! Validation is in progress.", flash[:notice]
  end

  test "create strips whitespace from the URL" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "  https://github.com/owner/repo  " } }

    course = Course.last
    assert_equal "https://github.com/owner/repo", course.github_repo_url
  end

  test "create parses owner and repo correctly from URL" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "https://github.com/my-org/my-project" } }

    course = Course.last
    assert_equal "my-org", course.github_owner
    assert_equal "my-project", course.github_repo
  end

  test "create sets title from repo name using titleize" do
    sign_in_as(@user)

    post courses_path, params: { course: { github_repo_url: "https://github.com/owner/my-cool-course" } }

    course = Course.last
    assert_equal "My Cool Course", course.title
  end

  test "create enqueues a validation job" do
    sign_in_as(@user)

    assert_enqueued_with(job: CourseValidationJob) do
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/validjob" } }
    end
  end

  test "create renders new with errors for invalid GitHub URL" do
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      post courses_path, params: { course: { github_repo_url: "https://gitlab.com/owner/repo" } }
    end

    assert_response :unprocessable_entity
    assert_select "div.bg-rose-light"
  end

  test "create renders new with errors for blank URL" do
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      post courses_path, params: { course: { github_repo_url: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "create renders new with errors for URL with extra path segments" do
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/repo/extra" } }
    end

    assert_response :unprocessable_entity
  end

  test "create renders new with errors for non-https URL" do
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      post courses_path, params: { course: { github_repo_url: "http://github.com/owner/repo" } }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects duplicate course with same owner and repo" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/dup-owner/dup-repo",
      github_owner: "dup-owner",
      github_repo: "dup-repo",
      title: "Existing Course"
    )
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      post courses_path, params: { course: { github_repo_url: "https://github.com/dup-owner/dup-repo" } }
    end

    assert_response :unprocessable_entity
  end

  test "create redirects to root when not signed in" do
    assert_no_difference "Course.count" do
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/repo" } }
    end

    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- show action ---

  test "show displays course details" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/show-owner/show-repo",
      github_owner: "show-owner",
      github_repo: "show-repo",
      title: "Show Test Course",
      status: "approved",
      description: "A test description",
      author_name: "Test Author",
      version: "1.0.0"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "h1", "Show Test Course"
    assert_select "a[href='https://github.com/show-owner/show-repo']", text: /show-owner\/show-repo/
    assert_select "p", "A test description"
    assert_select "p", "Test Author"
    assert_select "p", "1.0.0"
  end

  test "show displays course tags as links to filtered index" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-owner/tag-repo",
      github_owner: "tag-owner",
      github_repo: "tag-repo",
      title: "Tagged Course",
      status: "approved",
      tags: [ "ruby", "rails" ]
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "a[href='#{courses_path(tag: "ruby")}']", text: "ruby"
    assert_select "a[href='#{courses_path(tag: "rails")}']", text: "rails"
  end

  test "show is accessible without authentication for approved courses" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/public-owner/public-repo",
      github_owner: "public-owner",
      github_repo: "public-repo",
      title: "Public Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "h1", "Public Course"
  end

  test "show displays status badge" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/status-owner/status-repo",
      github_owner: "status-owner",
      github_repo: "status-repo",
      title: "Status Course",
      status: "pending"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "span.bg-mustard-light", "Pending"
  end

  test "show displays validation error for failed course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/fail-owner/fail-repo",
      github_owner: "fail-owner",
      github_repo: "fail-repo",
      title: "Failed Course",
      status: "failed",
      validation_error: "Repository not found"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "p.text-terracotta", "Repository not found"
  end

  test "show hides optional fields when blank" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/minimal-owner/minimal-repo",
      github_owner: "minimal-owner",
      github_repo: "minimal-repo",
      title: "Minimal Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "h2", { text: "Description", count: 0 }
    assert_select "h2", { text: "Author", count: 0 }
    assert_select "h2", { text: "Version", count: 0 }
    assert_select "h2", { text: "Tags", count: 0 }
  end

  test "show displays remove button for course owner" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/remove-owner/remove-repo",
      github_owner: "remove-owner",
      github_repo: "remove-repo",
      title: "Removable Course",
      status: "approved"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "button", "Remove Course"
  end

  test "show hides remove button for non-owner" do
    other_user = User.create!(github_id: "cc002", github_username: "otheruser", avatar_url: "https://example.com/other.png")
    course = Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/other-owner/other-repo",
      github_owner: "other-owner",
      github_repo: "other-repo",
      title: "Others Course",
      status: "approved"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "button", { text: "Remove Course", count: 0 }
  end

  test "show hides remove button for unauthenticated user" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/unauth-owner/unauth-repo",
      github_owner: "unauth-owner",
      github_repo: "unauth-repo",
      title: "Unauth Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "button", { text: "Remove Course", count: 0 }
  end

  test "show returns 404 for nonexistent course" do
    get course_path("nonexistent-owner", "nonexistent-repo")
    assert_response :not_found
  end

  test "show returns 404 for pending course when not signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/noview-owner/pending-noview",
      github_owner: "noview-owner",
      github_repo: "pending-noview",
      title: "Hidden Pending",
      status: "pending"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :not_found
  end

  test "show returns 404 for failed course when not signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/noview-owner/failed-noview",
      github_owner: "noview-owner",
      github_repo: "failed-noview",
      title: "Hidden Failed",
      status: "failed",
      validation_error: "Something went wrong"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :not_found
  end

  test "show returns 404 for validating course when not signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/noview-owner/validating-noview",
      github_owner: "noview-owner",
      github_repo: "validating-noview",
      title: "Hidden Validating",
      status: "validating"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :not_found
  end

  test "show allows owner to view their own pending course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/myview-owner/pending-myview",
      github_owner: "myview-owner",
      github_repo: "pending-myview",
      title: "My Pending Course",
      status: "pending"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "h1", "My Pending Course"
  end

  test "show allows owner to view their own failed course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/myview-owner/failed-myview",
      github_owner: "myview-owner",
      github_repo: "failed-myview",
      title: "My Failed Course",
      status: "failed",
      validation_error: "Some error"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "h1", "My Failed Course"
  end

  test "show returns 404 for non-approved course belonging to another user" do
    other_user = User.create!(github_id: "cc_view_other", github_username: "viewother", avatar_url: "https://example.com/other.png")
    course = Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/viewother-owner/pending-viewother",
      github_owner: "viewother-owner",
      github_repo: "pending-viewother",
      title: "Others Pending Course",
      status: "pending"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :not_found
  end

  test "show sets public cache headers for approved course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/cache-owner/cache-repo",
      github_owner: "cache-owner",
      github_repo: "cache-repo",
      title: "Cached Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_match(/max-age=300/, response.headers["Cache-Control"])
    assert_match(/public/, response.headers["Cache-Control"])
  end

  test "show does not set public cache headers for non-approved course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/nocache-owner/nocache-repo",
      github_owner: "nocache-owner",
      github_repo: "nocache-repo",
      title: "Uncached Course",
      status: "pending"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    cache_control = response.headers["Cache-Control"] || ""
    refute_match(/public/, cache_control)
  end

  test "show displays deep link button for approved course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/deep-owner/deep-repo",
      github_owner: "deep-owner",
      github_repo: "deep-repo",
      title: "Deep Link Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "a[href='courseimports://import/deep-owner/deep-repo']", text: "Open in app"
  end

  test "show deep link button has track-load stimulus controller" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/stimulus-owner/stimulus-repo",
      github_owner: "stimulus-owner",
      github_repo: "stimulus-repo",
      title: "Stimulus Track Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "a[data-controller='track-load'][data-action='click->track-load#track']", text: "Open in app"
    assert_select "a[data-track-load-url-value='#{track_load_course_path(course.github_owner, course.github_repo)}']"
  end

  test "show hides deep link button for non-approved course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/nodeep-owner/nodeep-repo",
      github_owner: "nodeep-owner",
      github_repo: "nodeep-repo",
      title: "No Deep Link Course",
      status: "pending"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "a", { text: "Open in app", count: 0 }
  end

  test "show renders detail partial with correct DOM id" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/detail-owner/detail-repo",
      github_owner: "detail-owner",
      github_repo: "detail-repo",
      title: "Detail Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "#course_#{course.id}"
  end

  test "show displays back to courses link" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/back-owner/back-repo",
      github_owner: "back-owner",
      github_repo: "back-repo",
      title: "Back Link Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "a[href='#{courses_path}']", text: /Back to courses/
  end

  test "show displays view on github button" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/ghbtn-owner/ghbtn-repo",
      github_owner: "ghbtn-owner",
      github_repo: "ghbtn-repo",
      title: "GitHub Button Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "a[href='https://github.com/ghbtn-owner/ghbtn-repo'][target='_blank'][rel='noopener noreferrer']", text: "View on GitHub"
  end

  test "show displays topic count when present" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/topic-show/topic-show-repo",
      github_owner: "topic-show",
      github_repo: "topic-show-repo",
      title: "Topic Show Course",
      status: "approved",
      topic_count: 12
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "p", text: "12 topics"
  end

  test "show hides topic count when nil" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/notopic-show/notopic-show-repo",
      github_owner: "notopic-show",
      github_repo: "notopic-show-repo",
      title: "No Topic Course",
      status: "approved",
      topic_count: nil
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "h2", { text: "Topics", count: 0 }
  end

  test "show displays load count" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/load-show/load-show-repo",
      github_owner: "load-show",
      github_repo: "load-show-repo",
      title: "Load Show Course",
      status: "approved",
      load_count: 7
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "p", text: "7 loads"
  end

  test "show displays zero load count" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/zeroload-show/zeroload-show-repo",
      github_owner: "zeroload-show",
      github_repo: "zeroload-show-repo",
      title: "Zero Load Course",
      status: "approved"
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "p", text: "0 loads"
  end

  test "show pluralizes topic count correctly for one topic" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/onetopic-show/onetopic-repo",
      github_owner: "onetopic-show",
      github_repo: "onetopic-repo",
      title: "One Topic Course",
      status: "approved",
      topic_count: 1
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "p", text: "1 topic"
  end

  test "show pluralizes load count correctly for one load" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/oneload-show/oneload-repo",
      github_owner: "oneload-show",
      github_repo: "oneload-repo",
      title: "One Load Course",
      status: "approved",
      load_count: 1
    )

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "p", text: "1 load"
  end

  # --- destroy action ---

  test "destroy deletes the course record and redirects" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/destroy-owner/destroy-repo",
      github_owner: "destroy-owner",
      github_repo: "destroy-repo",
      title: "Doomed Course",
      status: "approved"
    )
    sign_in_as(@user)

    assert_difference "Course.count", -1 do
      delete course_path(course.github_owner, course.github_repo)
    end

    assert_redirected_to dashboard_path
    assert_equal "Course removed.", flash[:notice]
    assert_not Course.exists?(course.id)
  end

  test "destroy returns 404 for another users course" do
    other_user = User.create!(github_id: "cc003", github_username: "destroyother", avatar_url: "https://example.com/other.png")
    course = Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/notmine-owner/notmine-repo",
      github_owner: "notmine-owner",
      github_repo: "notmine-repo",
      title: "Not Mine",
      status: "approved"
    )
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      delete course_path(course.github_owner, course.github_repo)
    end
    assert_response :not_found
  end

  test "destroy redirects to root when not signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/noauth-owner/noauth-repo",
      github_owner: "noauth-owner",
      github_repo: "noauth-repo",
      title: "No Auth Destroy",
      status: "approved"
    )

    assert_no_difference "Course.count" do
      delete course_path(course.github_owner, course.github_repo)
    end
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- index action (public browse) ---

  test "index displays approved courses without authentication" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/pub-owner/pub-repo",
      github_owner: "pub-owner",
      github_repo: "pub-repo",
      title: "Public Course",
      status: "approved"
    )

    get courses_path
    assert_response :success
    assert_select "h1", "Course Imports"
    assert_select "a", text: "Public Course"
  end

  test "index only shows approved courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/vis-owner/pending-vis",
      github_owner: "vis-owner",
      github_repo: "pending-vis",
      title: "Pending Course",
      status: "pending"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/vis-owner/failed-vis",
      github_owner: "vis-owner",
      github_repo: "failed-vis",
      title: "Failed Course",
      status: "failed",
      validation_error: "Some error"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/vis-owner/approved-vis",
      github_owner: "vis-owner",
      github_repo: "approved-vis",
      title: "Approved Course",
      status: "approved"
    )

    get courses_path
    assert_response :success
    assert_select "a", text: "Approved Course"
    assert_select "a", { text: "Pending Course", count: 0 }
    assert_select "a", { text: "Failed Course", count: 0 }
  end

  test "index shows courses from all users" do
    other_user = User.create!(github_id: "cc_other_idx", github_username: "otheridx", avatar_url: "https://example.com/other.png")
    Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/other-idx/other-idx-repo",
      github_owner: "other-idx",
      github_repo: "other-idx-repo",
      title: "Others Course",
      status: "approved"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/my-idx/my-idx-repo",
      github_owner: "my-idx",
      github_repo: "my-idx-repo",
      title: "My Course",
      status: "approved"
    )

    get courses_path
    assert_response :success
    assert_select "a", text: "Others Course"
    assert_select "a", text: "My Course"
  end

  test "index shows empty state when no approved courses exist" do
    get courses_path
    assert_response :success
    assert_select "p", /No courses have been approved yet/
  end

  test "index orders courses by most recent first" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-order/old-repo",
      github_owner: "idx-order",
      github_repo: "old-repo",
      title: "Old Course",
      status: "approved",
      created_at: 2.days.ago
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-order/new-repo",
      github_owner: "idx-order",
      github_repo: "new-repo",
      title: "New Course",
      status: "approved",
      created_at: 1.hour.ago
    )

    get courses_path
    assert_response :success
    response_body = @response.body
    new_pos = response_body.index("New Course")
    old_pos = response_body.index("Old Course")
    assert new_pos < old_pos, "New course should appear before old course"
  end

  test "index displays course description when present" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/desc-owner/desc-repo",
      github_owner: "desc-owner",
      github_repo: "desc-repo",
      title: "Described Course",
      status: "approved",
      description: "A detailed course description"
    )

    get courses_path
    assert_response :success
    assert_select "p", /A detailed course description/
  end

  test "index displays author name when present" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/auth-owner/auth-repo",
      github_owner: "auth-owner",
      github_repo: "auth-repo",
      title: "Authored Course",
      status: "approved",
      author_name: "Jane Author"
    )

    get courses_path
    assert_response :success
    assert_select "span", text: "Jane Author"
  end

  test "index falls back to github username when author name is absent" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/noauth-owner/noauth-repo",
      github_owner: "noauth-owner",
      github_repo: "noauth-repo",
      title: "No Author Course",
      status: "approved"
    )

    get courses_path
    assert_response :success
    assert_select "span", text: @user.github_username
  end

  test "index displays topic count when present" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/topic-idx/topic-idx-repo",
      github_owner: "topic-idx",
      github_repo: "topic-idx-repo",
      title: "Topic Course",
      status: "approved",
      topic_count: 5
    )

    get courses_path
    assert_response :success
    assert_select "span", text: "5 topics"
  end

  test "index displays tags when present" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-idx/tag-idx-repo",
      github_owner: "tag-idx",
      github_repo: "tag-idx-repo",
      title: "Tagged Course",
      status: "approved",
      tags: [ "ruby", "rails" ]
    )

    get courses_path
    assert_response :success
    assert_select "a", text: "ruby"
    assert_select "a", text: "rails"
  end

  test "index displays load count" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/load-idx/load-idx-repo",
      github_owner: "load-idx",
      github_repo: "load-idx-repo",
      title: "Loaded Course",
      status: "approved",
      load_count: 42
    )

    get courses_path
    assert_response :success
    assert_select "span", text: "42 loads"
  end

  test "index paginates with 20 courses per page" do
    21.times do |i|
      Course.create!(
        user: @user,
        github_repo_url: "https://github.com/page-owner/page-repo-#{i}",
        github_owner: "page-owner",
        github_repo: "page-repo-#{i}",
        title: "Page Course #{i}",
        status: "approved"
      )
    end

    get courses_path
    assert_response :success
    assert_select "a[href*='page=']"
  end

  test "index does not show pagination when courses fit on one page" do
    3.times do |i|
      Course.create!(
        user: @user,
        github_repo_url: "https://github.com/nopage-owner/nopage-repo-#{i}",
        github_owner: "nopage-owner",
        github_repo: "nopage-repo-#{i}",
        title: "No Page Course #{i}",
        status: "approved"
      )
    end

    get courses_path
    assert_response :success
    assert_select "a[href*='page=']", count: 0
  end

  test "index is accessible when signed in" do
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "h1", "Course Imports"
  end

  test "index shows sign-in button when not authenticated" do
    get root_path
    assert_select "form[action='/auth/github']" do
      assert_select "button", text: /Sign in with GitHub/
    end
  end

  test "index hides sign-in call-to-action when signed in" do
    sign_in_as(@user)

    get root_path
    assert_select "div.mb-8 form[action='/auth/github']", count: 0
  end

  # --- track_load action ---

  test "track_load creates a course load and increments load_count for signed-in user" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/track-repo",
      github_owner: "track-owner",
      github_repo: "track-repo",
      title: "Track Load Course",
      status: "approved"
    )
    sign_in_as(@user)

    assert_difference "CourseLoad.count", 1 do
      post track_load_course_path(course.github_owner, course.github_repo)
    end

    assert_response :no_content
    assert_equal 1, course.reload.load_count
    assert_equal "user_#{@user.id}", CourseLoad.last.identifier
  end

  test "track_load creates a course load for anonymous user using session" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/anon-track-repo",
      github_owner: "track-owner",
      github_repo: "anon-track-repo",
      title: "Anon Track Course",
      status: "approved"
    )

    assert_difference "CourseLoad.count", 1 do
      post track_load_course_path(course.github_owner, course.github_repo)
    end

    assert_response :no_content
    assert_equal 1, course.reload.load_count
    assert CourseLoad.last.identifier.start_with?("session_")
  end

  test "track_load deduplicates loads for the same signed-in user" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/dedup-repo",
      github_owner: "track-owner",
      github_repo: "dedup-repo",
      title: "Dedup Course",
      status: "approved"
    )
    sign_in_as(@user)

    post track_load_course_path(course.github_owner, course.github_repo)
    assert_response :no_content
    assert_equal 1, course.reload.load_count

    assert_no_difference "CourseLoad.count" do
      post track_load_course_path(course.github_owner, course.github_repo)
    end

    assert_response :no_content
    assert_equal 1, course.reload.load_count
  end

  test "track_load deduplicates loads for the same anonymous session" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/anon-dedup-repo",
      github_owner: "track-owner",
      github_repo: "anon-dedup-repo",
      title: "Anon Dedup Course",
      status: "approved"
    )

    post track_load_course_path(course.github_owner, course.github_repo)
    assert_response :no_content
    assert_equal 1, course.reload.load_count

    assert_no_difference "CourseLoad.count" do
      post track_load_course_path(course.github_owner, course.github_repo)
    end

    assert_response :no_content
    assert_equal 1, course.reload.load_count
  end

  test "track_load allows different users to each record a load" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/multi-user-repo",
      github_owner: "track-owner",
      github_repo: "multi-user-repo",
      title: "Multi User Course",
      status: "approved"
    )
    other_user = User.create!(github_id: "cc_track_other", github_username: "trackother", avatar_url: "https://example.com/other.png")

    sign_in_as(@user)
    post track_load_course_path(course.github_owner, course.github_repo)
    assert_equal 1, course.reload.load_count

    sign_in_as(other_user)
    post track_load_course_path(course.github_owner, course.github_repo)
    assert_equal 2, course.reload.load_count
    assert_equal 2, course.course_loads.count
  end

  test "track_load returns 404 for nonexistent course" do
    post track_load_course_path("nonexistent-owner", "nonexistent-repo")
    assert_response :not_found
  end

  test "track_load does not require authentication" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/noauth-track-repo",
      github_owner: "track-owner",
      github_repo: "noauth-track-repo",
      title: "No Auth Track Course",
      status: "approved"
    )

    post track_load_course_path(course.github_owner, course.github_repo)
    assert_response :no_content
  end

  test "track_load returns no_content even on duplicate" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/track-owner/dup-track-repo",
      github_owner: "track-owner",
      github_repo: "dup-track-repo",
      title: "Dup Track Course",
      status: "approved"
    )
    sign_in_as(@user)

    post track_load_course_path(course.github_owner, course.github_repo)
    post track_load_course_path(course.github_owner, course.github_repo)

    assert_response :no_content
  end

  # --- resubmit action ---

  test "resubmit resubmits a failed course for validation" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/resub-owner/resub-repo",
      github_owner: "resub-owner",
      github_repo: "resub-repo",
      title: "Failed Course",
      status: "failed",
      validation_error: "Repo not found"
    )
    sign_in_as(@user)

    assert_enqueued_with(job: CourseValidationJob) do
      post resubmit_course_path(course.github_owner, course.github_repo)
    end

    assert_redirected_to course_path(course.github_owner, course.github_repo)
    assert_equal "Course resubmitted for validation.", flash[:notice]
  end

  test "resubmit rejects non-failed course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/resub-owner/approved-resub",
      github_owner: "resub-owner",
      github_repo: "approved-resub",
      title: "Approved Course",
      status: "approved"
    )
    sign_in_as(@user)

    post resubmit_course_path(course.github_owner, course.github_repo)

    assert_redirected_to course_path(course.github_owner, course.github_repo)
    assert_equal "Only failed courses can be resubmitted.", flash[:alert]
  end

  test "resubmit rejects pending course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/resub-owner/pending-resub",
      github_owner: "resub-owner",
      github_repo: "pending-resub",
      title: "Pending Course",
      status: "pending"
    )
    sign_in_as(@user)

    post resubmit_course_path(course.github_owner, course.github_repo)

    assert_redirected_to course_path(course.github_owner, course.github_repo)
    assert_equal "Only failed courses can be resubmitted.", flash[:alert]
  end

  test "resubmit returns 404 for another users course" do
    other_user = User.create!(github_id: "cc_resub_other", github_username: "resubother", avatar_url: "https://example.com/other.png")
    course = Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/resub-other/other-repo",
      github_owner: "resub-other",
      github_repo: "other-repo",
      title: "Not Mine",
      status: "failed",
      validation_error: "Some error"
    )
    sign_in_as(@user)

    post resubmit_course_path(course.github_owner, course.github_repo)
    assert_response :not_found
  end

  test "resubmit redirects to root when not signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/resub-noauth/noauth-repo",
      github_owner: "resub-noauth",
      github_repo: "noauth-repo",
      title: "No Auth Resubmit",
      status: "failed",
      validation_error: "Some error"
    )

    post resubmit_course_path(course.github_owner, course.github_repo)
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- resubmit button on show ---

  test "show displays resubmit button for failed course owned by current user" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/resubshow-owner/resubshow-repo",
      github_owner: "resubshow-owner",
      github_repo: "resubshow-repo",
      title: "Failed Resubmit Course",
      status: "failed",
      validation_error: "Some error"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "button", text: "Resubmit for Validation"
  end

  test "show hides resubmit button for approved course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/noresub-owner/noresub-repo",
      github_owner: "noresub-owner",
      github_repo: "noresub-repo",
      title: "Approved No Resubmit",
      status: "approved"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    assert_select "button", { text: "Resubmit for Validation", count: 0 }
  end

  # --- new action (updated content) ---

  test "new form displays repository requirements" do
    sign_in_as(@user)

    get new_course_path
    assert_response :success
    assert_select "p", /Add a public GitHub repository to the course registry/
    assert_select "code", "course.json"
    assert_select "code", "topics/"
  end

  # --- index search ---

  test "index search returns matching approved courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-owner/ruby-course",
      github_owner: "srch-owner",
      github_repo: "ruby-course",
      title: "Ruby Fundamentals",
      status: "approved"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-owner/python-course",
      github_owner: "srch-owner",
      github_repo: "python-course",
      title: "Python Basics",
      status: "approved"
    )

    get courses_path, params: { q: "ruby" }
    assert_response :success
    assert_select "a", text: "Ruby Fundamentals"
    assert_select "a", { text: "Python Basics", count: 0 }
  end

  test "index search matches courses by description" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-desc/web-course",
      github_owner: "srch-desc",
      github_repo: "web-course",
      title: "Web Development",
      description: "Learn JavaScript and React",
      status: "approved"
    )

    get courses_path, params: { q: "javascript" }
    assert_response :success
    assert_select "a", text: "Web Development"
  end

  test "index search only returns approved courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-status/approved-srch",
      github_owner: "srch-status",
      github_repo: "approved-srch",
      title: "Approved Rails Course",
      status: "approved"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-status/pending-srch",
      github_owner: "srch-status",
      github_repo: "pending-srch",
      title: "Pending Rails Course",
      status: "pending"
    )

    get courses_path, params: { q: "rails" }
    assert_response :success
    assert_select "a", text: "Approved Rails Course"
    assert_select "a", { text: "Pending Rails Course", count: 0 }
  end

  test "index search preserves query in search field" do
    get courses_path, params: { q: "ruby" }
    assert_response :success
    assert_select "input[name='q'][value='ruby']"
  end

  test "index search with blank query returns all approved courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-blank/course-a",
      github_owner: "srch-blank",
      github_repo: "course-a",
      title: "Course Alpha",
      status: "approved"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-blank/course-b",
      github_owner: "srch-blank",
      github_repo: "course-b",
      title: "Course Beta",
      status: "approved"
    )

    get courses_path, params: { q: "" }
    assert_response :success
    assert_select "a", text: "Course Alpha"
    assert_select "a", text: "Course Beta"
  end

  test "index search shows no results message when search has no matches" do
    get courses_path, params: { q: "nonexistentxyzterm" }
    assert_response :success
    assert_select "p", /No courses found for "nonexistentxyzterm"/
  end

  test "index search no results shows clear search link" do
    get courses_path, params: { q: "nonexistentxyzterm" }
    assert_response :success
    assert_select "a[href='#{courses_path}']", text: "Clear filters"
  end

  test "index without search query shows default empty state" do
    get courses_path
    assert_response :success
    assert_select "p", /No courses have been approved yet/
  end

  test "index search form is present on the page" do
    get courses_path
    assert_response :success
    assert_select "form[action='#{courses_path}'][method='get']" do
      assert_select "input[name='q'][type='search']"
      assert_select "input[type='submit'][value='Search']"
    end
  end

  test "index without search query orders by created_at desc" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-order/old-repo",
      github_owner: "srch-order",
      github_repo: "old-repo",
      title: "Old Course",
      status: "approved",
      created_at: 2.days.ago
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-order/new-repo",
      github_owner: "srch-order",
      github_repo: "new-repo",
      title: "New Course",
      status: "approved",
      created_at: 1.hour.ago
    )

    get courses_path
    assert_response :success
    response_body = @response.body
    new_pos = response_body.index("New Course")
    old_pos = response_body.index("Old Course")
    assert new_pos < old_pos, "New course should appear before old course without search"
  end

  test "index search orders results by relevance" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-rel/desc-match",
      github_owner: "srch-rel",
      github_repo: "desc-match",
      title: "General Programming",
      description: "Includes some docker container topics",
      status: "approved"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/srch-rel/title-match",
      github_owner: "srch-rel",
      github_repo: "title-match",
      title: "Docker Containers Masterclass",
      description: "A comprehensive guide",
      status: "approved"
    )

    get courses_path, params: { q: "docker" }
    assert_response :success
    response_body = @response.body
    title_pos = response_body.index("Docker Containers Masterclass")
    desc_pos = response_body.index("General Programming")
    assert title_pos < desc_pos, "Title match should appear before description match"
  end

  test "index search handles special characters safely" do
    get courses_path, params: { q: "'; DROP TABLE courses; --" }
    assert_response :success
  end

  test "index search combines with pagination" do
    21.times do |i|
      Course.create!(
        user: @user,
        github_repo_url: "https://github.com/srch-page/srch-repo-#{i}",
        github_owner: "srch-page",
        github_repo: "srch-repo-#{i}",
        title: "Searchable Course #{i}",
        description: "This is a searchable programming course",
        status: "approved"
      )
    end

    get courses_path, params: { q: "searchable" }
    assert_response :success
    assert_select "a[href*='page=']"
  end

  # --- index tag filtering ---

  test "index with tag filter shows only courses with that tag" do
    tagged = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-filt/ruby-tagged",
      github_owner: "tag-filt",
      github_repo: "ruby-tagged",
      title: "Ruby Tagged Course",
      status: "approved",
      tags: [ "ruby", "web" ]
    )
    untagged = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-filt/python-untagged",
      github_owner: "tag-filt",
      github_repo: "python-untagged",
      title: "Python Untagged Course",
      status: "approved",
      tags: [ "python" ]
    )

    get courses_path, params: { tag: "ruby" }
    assert_response :success
    assert_select "a", text: "Ruby Tagged Course"
    assert_select "a", { text: "Python Untagged Course", count: 0 }
  end

  test "index with tag filter combines with search query" do
    both_match = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-combo/ruby-web",
      github_owner: "tag-combo",
      github_repo: "ruby-web",
      title: "Ruby Web Development",
      status: "approved",
      tags: [ "ruby" ]
    )
    tag_only = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-combo/ruby-data",
      github_owner: "tag-combo",
      github_repo: "ruby-data",
      title: "Ruby Data Science",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path, params: { q: "web", tag: "ruby" }
    assert_response :success
    assert_select "a", text: "Ruby Web Development"
    assert_select "a", { text: "Ruby Data Science", count: 0 }
  end

  test "index does not display standalone tag cloud" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-cloud/repo1",
      github_owner: "tag-cloud",
      github_repo: "repo1",
      title: "Course One",
      status: "approved",
      tags: [ "ruby", "web" ]
    )

    get courses_path
    assert_response :success
    assert_select "span", { text: "Tags:", count: 0 }
    assert_select "span", { text: "Filtered by:", count: 0 }
  end

  test "index shows filtered-by indicator with active tag" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-active/repo1",
      github_owner: "tag-active",
      github_repo: "repo1",
      title: "Active Tag Course",
      status: "approved",
      tags: [ "ruby", "python" ]
    )

    get courses_path, params: { tag: "ruby" }
    assert_response :success
    assert_select "span", text: "Filtered by:"
    assert_select "span.bg-rose.text-white", text: "ruby"
  end

  test "index shows clear filter link when tag is active" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-clear/repo1",
      github_owner: "tag-clear",
      github_repo: "repo1",
      title: "Clear Filter Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path, params: { tag: "ruby" }
    assert_response :success
    assert_select "a", text: "Clear filter"
  end

  test "index does not show clear filter link without active tag" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-noclear/repo1",
      github_owner: "tag-noclear",
      github_repo: "repo1",
      title: "No Clear Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path
    assert_response :success
    assert_select "a", { text: "Clear filter", count: 0 }
  end

  test "index filtered-by clear link preserves search query" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-clear-q/repo1",
      github_owner: "tag-clear-q",
      github_repo: "repo1",
      title: "Clear Query Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path, params: { tag: "ruby", q: "clear" }
    assert_response :success
    assert_select "a[href='#{courses_path(q: "clear")}']", text: "Clear filter"
  end

  test "index tag filter strips whitespace and downcases" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-sanitize/repo1",
      github_owner: "tag-sanitize",
      github_repo: "repo1",
      title: "Sanitize Tag Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path, params: { tag: "  Ruby  " }
    assert_response :success
    assert_select "a", text: "Sanitize Tag Course"
  end

  test "index with nonexistent tag shows no results with tag message" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-noexist/repo1",
      github_owner: "tag-noexist",
      github_repo: "repo1",
      title: "Existing Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path, params: { tag: "nonexistenttag" }
    assert_response :success
    assert_select "p", /tagged "nonexistenttag"/
    assert_select "a", text: "Clear filters"
  end

  test "index tag filter preserves tag in hidden field within search form" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-hidden/repo1",
      github_owner: "tag-hidden",
      github_repo: "repo1",
      title: "Hidden Field Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path, params: { tag: "ruby" }
    assert_response :success
    assert_select "input[name='tag'][type='hidden'][value='ruby']"
  end

  test "index tag filter does not add hidden tag field without active filter" do
    get courses_path
    assert_response :success
    assert_select "input[name='tag'][type='hidden']", count: 0
  end

  test "index course card tags link to tag-filtered index" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-link/repo1",
      github_owner: "tag-link",
      github_repo: "repo1",
      title: "Tag Link Course",
      status: "approved",
      tags: [ "ruby" ]
    )

    get courses_path
    assert_response :success
    assert_select "a[href='#{courses_path(tag: "ruby")}']", text: "ruby"
  end

  test "index tag filter combines with pagination" do
    21.times do |i|
      Course.create!(
        user: @user,
        github_repo_url: "https://github.com/tag-page/tag-repo-#{i}",
        github_owner: "tag-page",
        github_repo: "tag-repo-#{i}",
        title: "Paginated Tag Course #{i}",
        status: "approved",
        tags: [ "paginatedtag" ]
      )
    end

    get courses_path, params: { tag: "paginatedtag" }
    assert_response :success
    assert_select "a[href*='page=']"
  end

  test "index shows combined empty state for search and tag filter" do
    get courses_path, params: { q: "nonexistent", tag: "faketag" }
    assert_response :success
    assert_select "p", /No courses found/
    assert_select "p", /for "nonexistent"/
    assert_select "p", /tagged "faketag"/
  end

  test "index does not show filtered-by indicator without active tag" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/no-tags/repo1",
      github_owner: "no-tags",
      github_repo: "repo1",
      title: "No Tags Course",
      status: "approved",
      tags: []
    )

    get courses_path
    assert_response :success
    assert_select "span", { text: "Filtered by:", count: 0 }
  end

  # --- routing ---

  test "routes GET /courses/new to courses#new" do
    assert_routing({ path: "/courses/new", method: :get },
                   { controller: "courses", action: "new" })
  end

  test "routes POST /courses to courses#create" do
    assert_routing({ path: "/courses", method: :post },
                   { controller: "courses", action: "create" })
  end

  test "routes GET /courses/:github_owner/:github_repo to courses#show" do
    assert_routing({ path: "/courses/octocat/my-repo", method: :get },
                   { controller: "courses", action: "show", github_owner: "octocat", github_repo: "my-repo" })
  end

  test "routes DELETE /courses/:github_owner/:github_repo to courses#destroy" do
    assert_routing({ path: "/courses/octocat/my-repo", method: :delete },
                   { controller: "courses", action: "destroy", github_owner: "octocat", github_repo: "my-repo" })
  end

  test "routes root path to courses#index" do
    assert_recognizes({ controller: "courses", action: "index" }, { path: "/", method: :get })
  end

  test "routes GET /courses to courses#index" do
    assert_routing({ path: "/courses", method: :get },
                   { controller: "courses", action: "index" })
  end

  test "routes POST /courses/:github_owner/:github_repo/track_load to courses#track_load" do
    assert_routing({ path: "/courses/octocat/my-repo/track_load", method: :post },
                   { controller: "courses", action: "track_load", github_owner: "octocat", github_repo: "my-repo" })
  end

  test "routes POST /courses/:github_owner/:github_repo/resubmit to courses#resubmit" do
    assert_routing({ path: "/courses/octocat/my-repo/resubmit", method: :post },
                   { controller: "courses", action: "resubmit", github_owner: "octocat", github_repo: "my-repo" })
  end

  test "routes with owner containing dots are rejected by constraints" do
    assert_raises(ActionController::UrlGenerationError) do
      get course_path(".bad-owner", "repo")
    end
  end

  test "routes with repo starting with dot are rejected by constraints" do
    assert_raises(ActionController::UrlGenerationError) do
      get course_path("owner", ".hidden-repo")
    end
  end

  test "routes with owner containing special characters are rejected" do
    assert_raises(ActionController::UrlGenerationError) do
      get course_path("owner/../../etc", "repo")
    end
  end

  test "old numeric ID route does not match" do
    get "/courses/1"
    assert_response :not_found
  end

  test "old numeric ID route for track_load does not match" do
    post "/courses/1/track_load"
    assert_response :not_found
  end

  test "old numeric ID route for resubmit does not match" do
    post "/courses/1/resubmit"
    assert_response :not_found
  end

  test "routes with owner containing underscores are rejected" do
    assert_raises(ActionController::UrlGenerationError) do
      get course_path("owner_name", "repo")
    end
  end

  # --- strong parameters ---

  test "create only permits github_repo_url parameter" do
    sign_in_as(@user)

    post courses_path, params: {
      course: {
        github_repo_url: "https://github.com/owner/strongparams",
        status: "approved",
        title: "Hacked Title",
        github_owner: "hacked-owner"
      }
    }

    course = Course.last
    assert_equal "pending", course.status
    assert_equal "Strongparams", course.title
    assert_equal "owner", course.github_owner
  end

  # --- favouriting integration in courses controller ---

  test "show does not set public cache headers for approved course when signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/cache-signedin/cache-repo",
      github_owner: "cache-signedin",
      github_repo: "cache-repo",
      title: "Signed In Cache Course",
      status: "approved"
    )
    sign_in_as(@user)

    get course_path(course.github_owner, course.github_repo)
    assert_response :success
    cache_control = response.headers["Cache-Control"] || ""
    refute_match(/public/, cache_control)
  end

  test "index renders successfully for unauthenticated user with no favourites" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-fav/idx-repo",
      github_owner: "idx-fav",
      github_repo: "idx-repo",
      title: "Index Fav Course",
      status: "approved"
    )

    get courses_path
    assert_response :success
    assert_select "a", text: "Index Fav Course"
  end
end
