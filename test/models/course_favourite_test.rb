require "test_helper"

class CourseFavouriteTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(github_id: "fav-test-user", github_username: "favuser")
    @course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/fav-owner/fav-repo",
      github_owner: "fav-owner",
      github_repo: "fav-repo",
      title: "Favourite Test Course",
      status: "approved"
    )
  end

  test "valid favourite with user and course" do
    favourite = CourseFavourite.new(user: @user, course: @course)
    assert favourite.valid?
  end

  test "belongs to user" do
    favourite = CourseFavourite.create!(user: @user, course: @course)
    assert_equal @user, favourite.user
  end

  test "belongs to course" do
    favourite = CourseFavourite.create!(user: @user, course: @course)
    assert_equal @course, favourite.course
  end

  test "requires a user association" do
    favourite = CourseFavourite.new(course: @course)
    assert_not favourite.valid?
    assert_includes favourite.errors[:user], "must exist"
  end

  test "requires a course association" do
    favourite = CourseFavourite.new(user: @user)
    assert_not favourite.valid?
    assert_includes favourite.errors[:course], "must exist"
  end

  test "validates uniqueness of course_id scoped to user_id" do
    CourseFavourite.create!(user: @user, course: @course)
    duplicate = CourseFavourite.new(user: @user, course: @course)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:course_id], "has already been taken"
  end

  test "allows same course to be favourited by different users" do
    other_user = User.create!(github_id: "fav-other-user", github_username: "favother")
    CourseFavourite.create!(user: @user, course: @course)
    other_favourite = CourseFavourite.new(user: other_user, course: @course)
    assert other_favourite.valid?
  end

  test "allows same user to favourite different courses" do
    other_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/fav-owner/fav-other",
      github_owner: "fav-owner",
      github_repo: "fav-other",
      title: "Other Course",
      status: "approved"
    )
    CourseFavourite.create!(user: @user, course: @course)
    other_favourite = CourseFavourite.new(user: @user, course: other_course)
    assert other_favourite.valid?
  end
end
