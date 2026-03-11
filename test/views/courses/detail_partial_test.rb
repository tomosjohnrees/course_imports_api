require "test_helper"

class DetailPartialTest < ActionView::TestCase
  setup do
    @user = User.create!(github_id: "show-detail-user", github_username: "showdetailtester")
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

  test "renders with correct DOM id for turbo stream targeting" do
    course = build_course
    render partial: "courses/detail", locals: { course: course }

    assert_select "#course_#{course.id}"
  end

  test "renders the status partial" do
    course = build_course(status: "pending")
    render partial: "courses/detail", locals: { course: course }

    assert_select "span.bg-mustard-light", text: "Pending"
  end

  test "renders description when present" do
    course = build_course(description: "A great course about Ruby")
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", text: "Description"
    assert_select "p", text: "A great course about Ruby"
  end

  test "hides description when blank" do
    course = build_course(description: nil)
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", { text: "Description", count: 0 }
  end

  test "renders author when present" do
    course = build_course(author_name: "Jane Doe")
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", text: "Author"
    assert_select "p", text: "Jane Doe"
  end

  test "hides author when blank" do
    course = build_course(author_name: nil)
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", { text: "Author", count: 0 }
  end

  test "renders tags as links to filtered index" do
    course = build_course(tags: [ "ruby", "rails" ])
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", text: "Tags"
    assert_select "a[href='#{courses_path(tag: "ruby")}']", text: "ruby"
    assert_select "a[href='#{courses_path(tag: "rails")}']", text: "rails"
  end

  test "hides tags section when tags are empty" do
    course = build_course(tags: [])
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", { text: "Tags", count: 0 }
  end

  test "renders topic count when present" do
    course = build_course(topic_count: 5)
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", text: "Topics"
    assert_select "p", text: "5 topics"
  end

  test "hides topic count when nil" do
    course = build_course(topic_count: nil)
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", { text: "Topics", count: 0 }
  end

  test "renders load count" do
    course = build_course
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", text: "Loads"
    assert_select "p", text: "0 loads"
  end

  test "renders version when present" do
    course = build_course(version: "2.1.0")
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", text: "Version"
    assert_select "p", text: "2.1.0"
  end

  test "hides version when blank" do
    course = build_course(version: nil)
    render partial: "courses/detail", locals: { course: course }

    assert_select "h2", { text: "Version", count: 0 }
  end

  test "renders View on GitHub link as text link" do
    course = build_course
    render partial: "courses/detail", locals: { course: course }

    assert_select "a[href='#{course.github_repo_url}'][target='_blank'][rel='noopener noreferrer']", text: /View on GitHub/
  end

  test "renders Open in app link for approved course" do
    course = build_course(status: "approved")
    render partial: "courses/detail", locals: { course: course }

    assert_select "a[href='#{course.deep_link_url}']", text: "Open in app"
  end

  test "hides Open in app link for non-approved course" do
    course = build_course(status: "pending")
    render partial: "courses/detail", locals: { course: course }

    assert_select "a", { text: "Open in app", count: 0 }
  end

  test "Open in app link includes track-load stimulus controller" do
    course = build_course(status: "approved")
    render partial: "courses/detail", locals: { course: course }

    assert_select "a[data-controller='track-load'][data-action='click->track-load#track']", text: "Open in app"
  end

  test "renders pluralized topic count for single topic" do
    course = build_course(topic_count: 1)
    render partial: "courses/detail", locals: { course: course }

    assert_select "p", text: "1 topic"
  end
end
