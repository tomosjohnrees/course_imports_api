require "test_helper"

class StatusPartialTest < ActionView::TestCase
  setup do
    @user = User.create!(github_id: "view-test-user", github_username: "viewtester")
  end

  def build_course(status:, validation_error: nil)
    Course.create!(
      user: @user,
      github_repo_url: "https://github.com/owner/repo-#{status}",
      github_owner: "owner",
      github_repo: "repo-#{status}",
      title: "Test Course",
      status: status,
      validation_error: validation_error
    )
  end

  test "renders course status badge with correct DOM id" do
    course = build_course(status: "pending")
    render partial: "courses/status", locals: { course: course }

    assert_select "#course_#{course.id}"
    assert_select "span.bg-mustard-light", text: "Pending"
  end

  test "renders approved status badge" do
    course = build_course(status: "approved")
    render partial: "courses/status", locals: { course: course }

    assert_select "span.bg-sage-light", text: "Approved"
  end

  test "renders validating status badge" do
    course = build_course(status: "validating")
    render partial: "courses/status", locals: { course: course }

    assert_select "span.bg-sky-light"
  end

  test "renders failed status with validation error" do
    course = build_course(status: "failed", validation_error: "Repository is private")
    render partial: "courses/status", locals: { course: course }

    assert_select "span.bg-terracotta-light", text: "Failed"
    assert_select "p.text-terracotta", text: "Repository is private"
  end

  test "does not render validation error for failed course without error message" do
    course = build_course(status: "failed", validation_error: nil)
    render partial: "courses/status", locals: { course: course }

    assert_select "span.bg-terracotta-light", text: "Failed"
    assert_select "p.text-terracotta", count: 0
  end

  test "does not render validation error for non-failed statuses" do
    course = build_course(status: "approved")
    render partial: "courses/status", locals: { course: course }

    assert_select "p.text-terracotta", count: 0
  end

  test "renders removed status badge" do
    course = build_course(status: "removed")
    render partial: "courses/status", locals: { course: course }

    assert_select "span.bg-parchment", text: "Removed"
  end

  test "renders status heading" do
    course = build_course(status: "pending")
    render partial: "courses/status", locals: { course: course }

    assert_select "h2", text: "Status"
  end
end
