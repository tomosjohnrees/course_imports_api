require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates presence of github_id" do
    user = User.new(github_username: "testuser")
    assert_not user.valid?
    assert_includes user.errors[:github_id], "can't be blank"
  end

  test "validates presence of github_username" do
    user = User.new(github_id: "123")
    assert_not user.valid?
    assert_includes user.errors[:github_username], "can't be blank"
  end

  test "validates uniqueness of github_id" do
    User.create!(github_id: "123", github_username: "first")
    duplicate = User.new(github_id: "123", github_username: "second")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:github_id], "has already been taken"
  end

  test "encrypts github_token at rest" do
    user = User.create!(github_id: "123", github_username: "testuser", github_token: "ghp_secret123")
    raw_token = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql([ "SELECT github_token FROM users WHERE id = ?", user.id ])
    )
    assert_not_equal "ghp_secret123", raw_token
    assert_equal "ghp_secret123", user.reload.github_token
  end

  test "github_token is filtered from inspect output" do
    user = User.new(github_token: "ghp_secret123")
    assert_not_includes user.inspect, "ghp_secret123"
  end

  test "banned scope returns only banned users" do
    banned_user = User.create!(github_id: "1", github_username: "banned", banned: true)
    active_user = User.create!(github_id: "2", github_username: "active", banned: false)

    result = User.banned
    assert_includes result, banned_user
    assert_not_includes result, active_user
  end

  test "banned? returns true for banned users" do
    user = User.new(banned: true)
    assert user.banned?
  end

  test "banned? returns false for non-banned users" do
    user = User.new(banned: false)
    assert_not user.banned?
  end

  test "find_or_create_from_omniauth creates new user" do
    auth_hash = {
      "uid" => "12345",
      "info" => {
        "nickname" => "octocat",
        "name" => "The Octocat",
        "image" => "https://avatars.githubusercontent.com/u/12345"
      },
      "credentials" => {
        "token" => "ghp_token123"
      }
    }

    assert_difference "User.count", 1 do
      user = User.find_or_create_from_omniauth(auth_hash)
      assert_equal "12345", user.github_id
      assert_equal "octocat", user.github_username
      assert_equal "The Octocat", user.display_name
      assert_equal "https://avatars.githubusercontent.com/u/12345", user.avatar_url
      assert_equal "ghp_token123", user.github_token
    end
  end

  test "find_or_create_from_omniauth updates existing user" do
    existing = User.create!(github_id: "12345", github_username: "old_name", github_token: "old_token")

    auth_hash = {
      "uid" => "12345",
      "info" => {
        "nickname" => "new_name",
        "name" => "New Name",
        "image" => "https://new-avatar.com/img.png"
      },
      "credentials" => {
        "token" => "ghp_new_token"
      }
    }

    assert_no_difference "User.count" do
      user = User.find_or_create_from_omniauth(auth_hash)
      assert_equal existing.id, user.id
      assert_equal "new_name", user.github_username
      assert_equal "New Name", user.display_name
      assert_equal "https://new-avatar.com/img.png", user.avatar_url
      assert_equal "ghp_new_token", user.github_token
    end
  end

  test "find_or_create_from_omniauth raises on missing required fields" do
    auth_hash = {
      "uid" => "99999",
      "info" => {
        "nickname" => nil,
        "name" => "No Username"
      },
      "credentials" => {
        "token" => "ghp_token"
      }
    }

    assert_raises ActiveRecord::RecordInvalid do
      User.find_or_create_from_omniauth(auth_hash)
    end
  end

  test "banned defaults to false for new users" do
    user = User.create!(github_id: "300", github_username: "newuser")
    assert_equal false, user.banned
    assert_not user.banned?
  end

  test "find_or_create_from_omniauth coerces integer uid to string" do
    auth_hash = {
      "uid" => 77777,
      "info" => {
        "nickname" => "intuser",
        "name" => "Int User",
        "image" => "https://example.com/avatar.png"
      },
      "credentials" => {
        "token" => "ghp_int_token"
      }
    }

    user = User.find_or_create_from_omniauth(auth_hash)
    assert_equal "77777", user.github_id
    assert user.persisted?
  end

  test "find_or_create_from_omniauth handles missing optional fields" do
    auth_hash = {
      "uid" => "88888",
      "info" => {
        "nickname" => "sparse_user"
      },
      "credentials" => {}
    }

    user = User.find_or_create_from_omniauth(auth_hash)
    assert user.persisted?
    assert_equal "sparse_user", user.github_username
    assert_nil user.display_name
    assert_nil user.avatar_url
    assert_nil user.github_token
  end

  test "destroying user destroys associated courses" do
    user = User.create!(github_id: "destroy-courses-test", github_username: "destroycoursesuser")
    Course.create!(
      user: user,
      github_repo_url: "https://github.com/destroy/repo",
      github_owner: "destroy", github_repo: "repo",
      title: "Destroy Test", status: "pending"
    )

    assert_difference "Course.count", -1 do
      user.destroy
    end
  end

  test "destroying user cascades through courses to validation_attempts" do
    user = User.create!(github_id: "cascade-test", github_username: "cascadeuser")
    course = Course.create!(
      user: user,
      github_repo_url: "https://github.com/cascade/repo",
      github_owner: "cascade", github_repo: "repo",
      title: "Cascade Test", status: "approved"
    )
    ValidationAttempt.create!(course: course, result: "passed")
    ValidationAttempt.create!(course: course, result: "failed")

    assert_difference "ValidationAttempt.count", -2 do
      assert_difference "Course.count", -1 do
        user.destroy
      end
    end
  end

  test "destroying user with multiple courses removes all courses" do
    user = User.create!(github_id: "multi-destroy-test", github_username: "multidestroyuser")
    3.times do |i|
      Course.create!(
        user: user,
        github_repo_url: "https://github.com/multi-destroy/repo-#{i}",
        github_owner: "multi-destroy", github_repo: "repo-#{i}",
        title: "Course #{i}", status: %w[pending approved failed][i]
      )
    end

    assert_difference "Course.count", -3 do
      user.destroy
    end
  end

  test "has many course_favourites" do
    user = User.create!(github_id: "fav-has-many", github_username: "favhasmany")
    course1 = Course.create!(
      user: user,
      github_repo_url: "https://github.com/fav-hm/repo1",
      github_owner: "fav-hm", github_repo: "repo1",
      title: "Fav Course 1", status: "approved"
    )
    course2 = Course.create!(
      user: user,
      github_repo_url: "https://github.com/fav-hm/repo2",
      github_owner: "fav-hm", github_repo: "repo2",
      title: "Fav Course 2", status: "approved"
    )
    CourseFavourite.create!(user: user, course: course1)
    CourseFavourite.create!(user: user, course: course2)

    assert_equal 2, user.course_favourites.count
  end

  test "has many favourited_courses through course_favourites" do
    user = User.create!(github_id: "fav-through", github_username: "favthrough")
    course1 = Course.create!(
      user: user,
      github_repo_url: "https://github.com/fav-through/repo1",
      github_owner: "fav-through", github_repo: "repo1",
      title: "Through Course 1", status: "approved"
    )
    course2 = Course.create!(
      user: user,
      github_repo_url: "https://github.com/fav-through/repo2",
      github_owner: "fav-through", github_repo: "repo2",
      title: "Through Course 2", status: "approved"
    )
    CourseFavourite.create!(user: user, course: course1)
    CourseFavourite.create!(user: user, course: course2)

    assert_equal 2, user.favourited_courses.count
    assert_includes user.favourited_courses, course1
    assert_includes user.favourited_courses, course2
  end

  test "destroying user deletes associated course_favourites" do
    user = User.create!(github_id: "fav-destroy", github_username: "favdestroy")
    course = Course.create!(
      user: user,
      github_repo_url: "https://github.com/fav-destroy/repo",
      github_owner: "fav-destroy", github_repo: "repo",
      title: "Fav Destroy Test", status: "approved"
    )
    CourseFavourite.create!(user: user, course: course)

    assert_difference "CourseFavourite.count", -1 do
      user.destroy
    end
  end

  test "find_or_create_from_omniauth does not change banned status on update" do
    existing = User.create!(github_id: "66666", github_username: "banned_user", banned: true)

    auth_hash = {
      "uid" => "66666",
      "info" => {
        "nickname" => "banned_user",
        "name" => "Banned User"
      },
      "credentials" => {
        "token" => "ghp_banned_token"
      }
    }

    user = User.find_or_create_from_omniauth(auth_hash)
    assert_equal true, user.banned?
  end
end
