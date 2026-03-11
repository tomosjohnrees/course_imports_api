require "test_helper"

class CourseFavouritesControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "cf001",
      github_username: "favctrluser",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_test_token"
    )
    @course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/fav-ctrl/fav-repo",
      github_owner: "fav-ctrl",
      github_repo: "fav-repo",
      title: "Favouritable Course",
      status: "approved"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  # --- index action ---

  test "index lists current users favourited courses when signed in" do
    CourseFavourite.create!(user: @user, course: @course)
    sign_in_as(@user)

    get favourites_path
    assert_response :success
    assert_select "h1", "My Favourites"
    assert_select "a", text: "Favouritable Course"
  end

  test "index does not show unfavourited courses" do
    other_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/fav-ctrl/unfav-repo",
      github_owner: "fav-ctrl",
      github_repo: "unfav-repo",
      title: "Unfavourited Course",
      status: "approved"
    )
    CourseFavourite.create!(user: @user, course: @course)
    sign_in_as(@user)

    get favourites_path
    assert_response :success
    assert_select "a", text: "Favouritable Course"
    assert_select "a", { text: "Unfavourited Course", count: 0 }
  end

  test "index only shows approved favourited courses" do
    pending_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/fav-ctrl/pending-repo",
      github_owner: "fav-ctrl",
      github_repo: "pending-repo",
      title: "Pending Favourite",
      status: "pending"
    )
    CourseFavourite.create!(user: @user, course: pending_course)
    sign_in_as(@user)

    get favourites_path
    assert_response :success
    assert_select "a", { text: "Pending Favourite", count: 0 }
  end

  test "index does not show other users favourites" do
    other_user = User.create!(github_id: "cf_other", github_username: "otherfav", avatar_url: "https://example.com/other.png")
    CourseFavourite.create!(user: other_user, course: @course)
    sign_in_as(@user)

    get favourites_path
    assert_response :success
    assert_select "a", { text: "Favouritable Course", count: 0 }
  end

  test "index shows empty state when user has no favourites" do
    sign_in_as(@user)

    get favourites_path
    assert_response :success
    assert_select "p", /You haven't favourited any courses yet/
  end

  test "index redirects to root when not signed in" do
    get favourites_path
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- create action ---

  test "create adds a favourite for the current user" do
    sign_in_as(@user)

    assert_difference "CourseFavourite.count", 1 do
      post favourite_course_path(@course.github_owner, @course.github_repo)
    end

    favourite = CourseFavourite.last
    assert_equal @user.id, favourite.user_id
    assert_equal @course.id, favourite.course_id
  end

  test "create redirects back with notice" do
    sign_in_as(@user)

    post favourite_course_path(@course.github_owner, @course.github_repo)
    assert_equal "Course added to favourites.", flash[:notice]
  end

  test "create handles duplicate favourite gracefully" do
    CourseFavourite.create!(user: @user, course: @course)
    sign_in_as(@user)

    assert_no_difference "CourseFavourite.count" do
      post favourite_course_path(@course.github_owner, @course.github_repo)
    end

    assert_equal "Course is already in your favourites.", flash[:notice]
  end

  test "create returns 404 for non-existent course" do
    sign_in_as(@user)

    post favourite_course_path("nonexistent", "nonexistent")
    assert_response :not_found
  end

  test "create redirects to root when not signed in" do
    post favourite_course_path(@course.github_owner, @course.github_repo)
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end

  # --- destroy action ---

  test "destroy removes a favourite for the current user" do
    CourseFavourite.create!(user: @user, course: @course)
    sign_in_as(@user)

    assert_difference "CourseFavourite.count", -1 do
      delete favourite_course_path(@course.github_owner, @course.github_repo)
    end
  end

  test "destroy redirects back with notice" do
    CourseFavourite.create!(user: @user, course: @course)
    sign_in_as(@user)

    delete favourite_course_path(@course.github_owner, @course.github_repo)
    assert_equal "Course removed from favourites.", flash[:notice]
  end

  test "destroy returns 404 when favourite does not exist" do
    sign_in_as(@user)

    delete favourite_course_path(@course.github_owner, @course.github_repo)
    assert_response :not_found
  end

  test "destroy cannot remove another users favourite" do
    other_user = User.create!(github_id: "cf_destroy_other", github_username: "destroyother", avatar_url: "https://example.com/other.png")
    CourseFavourite.create!(user: other_user, course: @course)
    sign_in_as(@user)

    delete favourite_course_path(@course.github_owner, @course.github_repo)
    assert_response :not_found
    assert_equal 1, CourseFavourite.count
  end

  test "destroy redirects to root when not signed in" do
    delete favourite_course_path(@course.github_owner, @course.github_repo)
    assert_redirected_to root_path
    assert_equal "You must sign in to continue.", flash[:alert]
  end
end
