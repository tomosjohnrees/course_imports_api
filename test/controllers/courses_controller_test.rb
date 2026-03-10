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

    assert_redirected_to course_path(course)
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
    assert_select "div.bg-red-50"
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

    get course_path(course)
    assert_response :success
    assert_select "h1", "Show Test Course"
    assert_select "a[href='https://github.com/show-owner/show-repo']", text: /show-owner\/show-repo/
    assert_select "p", "A test description"
    assert_select "p", "Test Author"
    assert_select "p", "1.0.0"
  end

  test "show displays course tags" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/tag-owner/tag-repo",
      github_owner: "tag-owner",
      github_repo: "tag-repo",
      title: "Tagged Course",
      status: "approved",
      tags: [ "ruby", "rails" ]
    )

    get course_path(course)
    assert_response :success
    assert_select "span", "ruby"
    assert_select "span", "rails"
  end

  test "show is accessible without authentication" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/public-owner/public-repo",
      github_owner: "public-owner",
      github_repo: "public-repo",
      title: "Public Course"
    )

    get course_path(course)
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

    get course_path(course)
    assert_response :success
    assert_select "span.bg-yellow-100", "Pending"
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

    get course_path(course)
    assert_response :success
    assert_select "p.text-red-700", "Repository not found"
  end

  test "show hides optional fields when blank" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/minimal-owner/minimal-repo",
      github_owner: "minimal-owner",
      github_repo: "minimal-repo",
      title: "Minimal Course",
      status: "pending"
    )

    get course_path(course)
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

    get course_path(course)
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

    get course_path(course)
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

    get course_path(course)
    assert_response :success
    assert_select "button", { text: "Remove Course", count: 0 }
  end

  test "show hides remove button for already removed course" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/removed-owner/removed-repo",
      github_owner: "removed-owner",
      github_repo: "removed-repo",
      title: "Removed Course",
      status: "removed"
    )
    sign_in_as(@user)

    get course_path(course)
    assert_response :success
    assert_select "button", { text: "Remove Course", count: 0 }
  end

  test "show returns 404 for nonexistent course" do
    get course_path(id: 999999)
    assert_response :not_found
  end

  # --- destroy action ---

  test "destroy sets course status to removed and redirects" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/destroy-owner/destroy-repo",
      github_owner: "destroy-owner",
      github_repo: "destroy-repo",
      title: "Doomed Course",
      status: "approved"
    )
    sign_in_as(@user)

    delete course_path(course)

    assert_redirected_to courses_path
    assert_equal "Course removed.", flash[:notice]
    assert_equal "removed", course.reload.status
  end

  test "destroy does not delete the course record" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/nodelete-owner/nodelete-repo",
      github_owner: "nodelete-owner",
      github_repo: "nodelete-repo",
      title: "Still Exists",
      status: "approved"
    )
    sign_in_as(@user)

    assert_no_difference "Course.count" do
      delete course_path(course)
    end
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

    delete course_path(course)
    assert_response :not_found
    assert_equal "approved", course.reload.status
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

    delete course_path(course)
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
    assert_equal "approved", course.reload.status
  end

  # --- index action ---

  test "index lists current users courses when signed in" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-owner/idx-repo",
      github_owner: "idx-owner",
      github_repo: "idx-repo",
      title: "My Listed Course",
      status: "approved"
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "h1", "My Courses"
    assert_select "a", text: "My Listed Course"
  end

  test "index does not show other users courses" do
    other_user = User.create!(github_id: "cc_other_idx", github_username: "otheridx", avatar_url: "https://example.com/other.png")
    Course.create!(
      user: other_user,
      github_repo_url: "https://github.com/other-idx/other-idx-repo",
      github_owner: "other-idx",
      github_repo: "other-idx-repo",
      title: "Others Course",
      status: "approved"
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "a", { text: "Others Course", count: 0 }
  end

  test "index redirects to root when not signed in" do
    get courses_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  test "index shows empty state when user has no courses" do
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "p", /You haven't submitted any courses yet/
    assert_select "a", text: "Submit your first course"
  end

  test "index shows status badges for each course" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-badge/pending-repo",
      github_owner: "idx-badge",
      github_repo: "pending-repo",
      title: "Pending Course",
      status: "pending"
    )
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-badge/approved-repo",
      github_owner: "idx-badge",
      github_repo: "approved-repo",
      title: "Approved Course",
      status: "approved"
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "span.bg-yellow-100", text: "Pending"
    assert_select "span.bg-green-100", text: "Approved"
  end

  test "index shows remove button for non-removed courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-rm/active-repo",
      github_owner: "idx-rm",
      github_repo: "active-repo",
      title: "Active Course",
      status: "approved"
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "button", text: "Remove"
  end

  test "index hides remove button for removed courses" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-rm/removed-repo",
      github_owner: "idx-rm",
      github_repo: "removed-repo",
      title: "Removed Course",
      status: "removed"
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "button", { text: "Remove", count: 0 }
  end

  test "index displays github owner and repo for each course" do
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-meta/meta-repo",
      github_owner: "idx-meta",
      github_repo: "meta-repo",
      title: "Meta Course",
      status: "approved"
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "p", text: "idx-meta/meta-repo"
  end

  test "index orders courses by most recent first" do
    old_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-order/old-repo",
      github_owner: "idx-order",
      github_repo: "old-repo",
      title: "Old Course",
      status: "approved",
      created_at: 2.days.ago
    )
    new_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/idx-order/new-repo",
      github_owner: "idx-order",
      github_repo: "new-repo",
      title: "New Course",
      status: "approved",
      created_at: 1.hour.ago
    )
    sign_in_as(@user)

    get courses_path
    assert_response :success
    response_body = @response.body
    new_pos = response_body.index("New Course")
    old_pos = response_body.index("Old Course")
    assert new_pos < old_pos, "New course should appear before old course"
  end

  test "index includes submit course link" do
    sign_in_as(@user)

    get courses_path
    assert_response :success
    assert_select "a[href='#{new_course_path}']", text: "Submit Course"
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
      post resubmit_course_path(course)
    end

    assert_redirected_to course_path(course)
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

    post resubmit_course_path(course)

    assert_redirected_to course_path(course)
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

    post resubmit_course_path(course)

    assert_redirected_to course_path(course)
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

    post resubmit_course_path(course)
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

    post resubmit_course_path(course)
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- show action (new features) ---

  test "show displays topic count when present" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/topic-owner/topic-repo",
      github_owner: "topic-owner",
      github_repo: "topic-repo",
      title: "Topic Course",
      status: "approved",
      topic_count: 5
    )

    get course_path(course)
    assert_response :success
    assert_select "h2", text: "Topics"
    assert_select "p", text: "5"
  end

  test "show hides topic count when zero" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/notopic-owner/notopic-repo",
      github_owner: "notopic-owner",
      github_repo: "notopic-repo",
      title: "No Topic Course",
      status: "approved",
      topic_count: 0
    )

    get course_path(course)
    assert_response :success
    assert_select "h2", { text: "Topics", count: 0 }
  end

  test "show hides topic count when nil" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/niltopic-owner/niltopic-repo",
      github_owner: "niltopic-owner",
      github_repo: "niltopic-repo",
      title: "Nil Topic Course",
      status: "pending"
    )

    get course_path(course)
    assert_response :success
    assert_select "h2", { text: "Topics", count: 0 }
  end

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

    get course_path(course)
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

    get course_path(course)
    assert_response :success
    assert_select "button", { text: "Resubmit for Validation", count: 0 }
  end

  test "show hides resubmit button for unauthenticated user" do
    course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/unauth-resub/unauth-resub-repo",
      github_owner: "unauth-resub",
      github_repo: "unauth-resub-repo",
      title: "Unauth Resubmit Course",
      status: "failed",
      validation_error: "Some error"
    )

    get course_path(course)
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

  # --- routing ---

  test "routes GET /courses/new to courses#new" do
    assert_routing({ path: "/courses/new", method: :get },
                   { controller: "courses", action: "new" })
  end

  test "routes POST /courses to courses#create" do
    assert_routing({ path: "/courses", method: :post },
                   { controller: "courses", action: "create" })
  end

  test "routes GET /courses/:id to courses#show" do
    assert_routing({ path: "/courses/1", method: :get },
                   { controller: "courses", action: "show", id: "1" })
  end

  test "routes DELETE /courses/:id to courses#destroy" do
    assert_routing({ path: "/courses/1", method: :delete },
                   { controller: "courses", action: "destroy", id: "1" })
  end

  test "routes GET /courses to courses#index" do
    assert_routing({ path: "/courses", method: :get },
                   { controller: "courses", action: "index" })
  end

  test "routes POST /courses/:id/resubmit to courses#resubmit" do
    assert_routing({ path: "/courses/1/resubmit", method: :post },
                   { controller: "courses", action: "resubmit", id: "1" })
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
end
