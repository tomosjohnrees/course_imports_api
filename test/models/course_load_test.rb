require "test_helper"

class CourseLoadTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(github_id: "cl-test-user", github_username: "cluser")
    @course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/cl-owner/cl-repo",
      github_owner: "cl-owner",
      github_repo: "cl-repo",
      title: "Course Load Test",
      status: "approved"
    )
  end

  test "valid course load with identifier and course" do
    course_load = CourseLoad.new(course: @course, identifier: "user_1")
    assert course_load.valid?
  end

  test "belongs to course" do
    course_load = CourseLoad.create!(course: @course, identifier: "user_1")
    assert_equal @course, course_load.course
  end

  test "validates presence of identifier" do
    course_load = CourseLoad.new(course: @course, identifier: nil)
    assert_not course_load.valid?
    assert_includes course_load.errors[:identifier], "can't be blank"
  end

  test "validates identifier cannot be blank string" do
    course_load = CourseLoad.new(course: @course, identifier: "")
    assert_not course_load.valid?
    assert_includes course_load.errors[:identifier], "can't be blank"
  end

  test "validates uniqueness of identifier scoped to course" do
    CourseLoad.create!(course: @course, identifier: "user_1")
    duplicate = CourseLoad.new(course: @course, identifier: "user_1")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:identifier], "has already been taken"
  end

  test "allows same identifier on different courses" do
    other_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/cl-owner/cl-other",
      github_owner: "cl-owner",
      github_repo: "cl-other",
      title: "Other Course",
      status: "approved"
    )

    CourseLoad.create!(course: @course, identifier: "user_1")
    other_load = CourseLoad.new(course: other_course, identifier: "user_1")
    assert other_load.valid?
  end

  test "allows different identifiers on the same course" do
    CourseLoad.create!(course: @course, identifier: "user_1")
    other_load = CourseLoad.new(course: @course, identifier: "session_abc123")
    assert other_load.valid?
  end

  test "requires a course association" do
    course_load = CourseLoad.new(identifier: "user_1")
    assert_not course_load.valid?
    assert_includes course_load.errors[:course], "must exist"
  end
end
