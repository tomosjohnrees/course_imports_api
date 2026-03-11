require "test_helper"

class DashboardEntryPartialTest < ActionView::TestCase
  setup do
    @user = User.create!(github_id: "dash-entry-user", github_username: "dashentrytester")
  end

  def build_course(attrs = {})
    slug = SecureRandom.hex(4)
    owner = attrs.delete(:github_owner) || "dash-owner"
    repo = attrs.delete(:github_repo) || "dash-repo-#{slug}"
    defaults = {
      user: @user,
      github_repo_url: "https://github.com/#{owner}/#{repo}",
      github_owner: owner,
      github_repo: repo,
      title: "Dashboard Course",
      status: "approved"
    }
    Course.create!(**defaults.merge(attrs))
  end

  test "renders with correct DOM id for turbo stream targeting" do
    course = build_course
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "#dashboard_course_#{course.id}"
  end

  test "renders course title as a link to the course page" do
    course = build_course(title: "My Ruby Course")
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "a[href='#{course_path(course.github_owner, course.github_repo)}']", text: "My Ruby Course"
  end

  test "renders github owner and repo" do
    course = build_course(github_owner: "acme", github_repo: "cool-course")
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "p", text: "acme/cool-course"
  end

  test "renders status badge" do
    course = build_course(status: "pending")
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "span.bg-mustard-light", text: "Pending"
  end

  test "renders approved status badge" do
    course = build_course(status: "approved")
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "span.bg-sage-light", text: "Approved"
  end

  test "renders failed status badge" do
    course = build_course(status: "failed", validation_error: "Something went wrong")
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "span.bg-terracotta-light", text: "Failed"
  end

  test "renders validating status badge" do
    course = build_course(status: "validating")
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "span.bg-sky-light"
  end

  test "renders remove button" do
    course = build_course
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "button", text: "Remove"
  end

  test "remove button uses delete method with turbo confirmation" do
    course = build_course
    render partial: "courses/dashboard_entry", locals: { course: course }

    assert_select "form[method='post']" do
      assert_select "input[name='_method'][value='delete']", visible: :all
      assert_select "button[data-turbo-confirm]", text: "Remove"
    end
  end
end
