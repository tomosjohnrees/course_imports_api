require "test_helper"

class CourseCardPartialTest < ActionView::TestCase
  helper do
    def user_signed_in? = false
  end

  setup do
    @user = User.create!(github_id: "card-test-user", github_username: "cardtester")
  end

  def build_course(attrs = {})
    slug = SecureRandom.hex(4)
    defaults = {
      user: @user,
      github_repo_url: "https://github.com/owner/repo-#{slug}",
      github_owner: "owner",
      github_repo: "repo-#{slug}",
      title: "Test Course",
      status: "approved"
    }
    Course.create!(**defaults.merge(attrs))
  end

  test "renders course title as link to course page" do
    course = build_course(title: "Ruby Basics")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a", text: "Ruby Basics"
  end

  test "renders Open in app link for approved course" do
    course = build_course(status: "approved")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[href='#{course.deep_link_url}']", text: "Open in app"
  end

  test "hides Open in app link for pending course" do
    course = build_course(status: "pending")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a", { text: "Open in app", count: 0 }
  end

  test "Open in app link includes track-load stimulus controller" do
    course = build_course(status: "approved")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[data-controller='track-load'][data-action='click->track-load#track']", text: "Open in app"
  end

  test "Open in app link includes track-load URL value" do
    course = build_course(status: "approved")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[data-track-load-url-value='#{track_load_course_path(course.github_owner, course.github_repo)}']"
  end

  test "renders View on GitHub link" do
    course = build_course
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[href='#{course.github_repo_url}'][target='_blank'][rel='noopener noreferrer']", text: /View on GitHub/
  end

  test "View on GitHub link is always present regardless of status" do
    course = build_course(status: "pending")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[href='#{course.github_repo_url}']", text: /View on GitHub/
  end

  test "renders description when present" do
    course = build_course(description: "Learn Ruby from scratch")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "p", text: "Learn Ruby from scratch"
  end

  test "hides description when blank" do
    course = build_course(description: nil)
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "p.line-clamp-2", count: 0
  end

  test "renders author name when present" do
    course = build_course(author_name: "Jane Doe")
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "span", text: "Jane Doe"
  end

  test "falls back to github username when author name is absent" do
    course = build_course(author_name: nil)
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "span", text: @user.github_username
  end

  test "renders topic count when present" do
    course = build_course(topic_count: 8)
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "span", text: "8 topics"
  end

  test "hides topic count when nil" do
    course = build_course(topic_count: nil)
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "span", { text: /topics?/, count: 0 }
  end

  test "renders load count" do
    course = build_course(load_count: 5)
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "span", text: "5 loads"
  end

  test "renders tags as links to filtered index" do
    course = build_course(tags: [ "ruby", "rails" ])
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[href='#{courses_path(tag: "ruby")}']", text: "ruby"
    assert_select "a[href='#{courses_path(tag: "rails")}']", text: "rails"
  end

  test "hides tags section when tags are empty" do
    course = build_course(tags: [])
    render partial: "courses/course_card", locals: { course: course, favourited: false }

    assert_select "a[href*='tag=']", count: 0
  end
end
