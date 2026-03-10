require "test_helper"

class CourseTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(github_id: "course-test-user", github_username: "coursetester")
    @valid_attributes = {
      user: @user,
      github_repo_url: "https://github.com/owner/repo",
      github_owner: "owner",
      github_repo: "repo",
      title: "My Course",
      status: "pending"
    }
  end

  test "valid course with all required attributes" do
    course = Course.new(@valid_attributes)
    assert course.valid?
  end

  test "validates presence of github_repo_url" do
    course = Course.new(@valid_attributes.merge(github_repo_url: nil))
    assert_not course.valid?
    assert_includes course.errors[:github_repo_url], "can't be blank"
  end

  test "validates presence of github_owner" do
    course = Course.new(@valid_attributes.merge(github_owner: nil))
    assert_not course.valid?
    assert_includes course.errors[:github_owner], "can't be blank"
  end

  test "validates presence of github_repo" do
    course = Course.new(@valid_attributes.merge(github_repo: nil))
    assert_not course.valid?
    assert_includes course.errors[:github_repo], "can't be blank"
  end

  test "validates presence of title" do
    course = Course.new(@valid_attributes.merge(title: nil))
    assert_not course.valid?
    assert_includes course.errors[:title], "can't be blank"
  end

  test "validates presence of status" do
    course = Course.new(@valid_attributes.merge(status: nil))
    assert_not course.valid?
    assert_includes course.errors[:status], "can't be blank"
  end

  test "validates status inclusion in STATUSES" do
    course = Course.new(@valid_attributes.merge(status: "invalid_status"))
    assert_not course.valid?
    assert_includes course.errors[:status], "is not included in the list"
  end

  test "accepts all valid statuses" do
    Course.statuses.each_key do |status|
      course = Course.new(@valid_attributes.merge(status: status, github_owner: "owner-#{status}", github_repo: "repo-#{status}"))
      assert course.valid?, "Expected status '#{status}' to be valid, but got errors: #{course.errors.full_messages}"
    end
  end

  test "statuses enum contains expected values" do
    assert_equal %w[pending validating approved failed removed], Course.statuses.keys
  end

  test "validates github_repo_url format accepts valid GitHub URLs" do
    valid_urls = [
      "https://github.com/owner/repo",
      "https://github.com/my-org/my-repo",
      "https://github.com/user123/project_name",
      "https://github.com/User.Name/Repo.Name"
    ]

    valid_urls.each do |url|
      course = Course.new(@valid_attributes.merge(github_repo_url: url, github_owner: "unique-#{url.hash.abs}", github_repo: "repo-#{url.hash.abs}"))
      assert course.valid?, "Expected '#{url}' to be valid, but got errors: #{course.errors.full_messages}"
    end
  end

  test "validates github_repo_url format rejects non-GitHub URLs" do
    invalid_urls = [
      "https://gitlab.com/owner/repo",
      "http://github.com/owner/repo",
      "https://github.com/owner",
      "https://github.com/",
      "https://github.com/owner/repo/extra",
      "ftp://github.com/owner/repo",
      "not-a-url",
      ""
    ]

    invalid_urls.each do |url|
      course = Course.new(@valid_attributes.merge(github_repo_url: url))
      assert_not course.valid?, "Expected '#{url}' to be invalid"
    end
  end

  test "validates uniqueness of github_owner scoped to github_repo" do
    Course.create!(@valid_attributes)
    duplicate = Course.new(@valid_attributes.merge(title: "Different Title", github_repo_url: "https://github.com/owner/repo"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:github_owner], "has already been taken"
  end

  test "allows same github_owner with different github_repo" do
    Course.create!(@valid_attributes)
    different_repo = Course.new(@valid_attributes.merge(github_repo: "different-repo", github_repo_url: "https://github.com/owner/different-repo"))
    assert different_repo.valid?
  end

  test "allows same github_repo with different github_owner" do
    Course.create!(@valid_attributes)
    different_owner = Course.new(@valid_attributes.merge(github_owner: "different-owner", github_repo_url: "https://github.com/different-owner/repo"))
    assert different_owner.valid?
  end

  test "belongs to user" do
    course = Course.new(@valid_attributes)
    assert_equal @user, course.user
  end

  test "has many validation_attempts" do
    course = Course.create!(@valid_attributes)
    attempt1 = ValidationAttempt.create!(course: course, result: "passed")
    attempt2 = ValidationAttempt.create!(course: course, result: "failed")

    assert_equal 2, course.validation_attempts.count
    assert_includes course.validation_attempts, attempt1
    assert_includes course.validation_attempts, attempt2
  end

  test "destroying course destroys associated validation_attempts" do
    course = Course.create!(@valid_attributes)
    ValidationAttempt.create!(course: course, result: "passed")
    ValidationAttempt.create!(course: course, result: "failed")

    assert_difference "ValidationAttempt.count", -2 do
      course.destroy
    end
  end

  test "pending scope returns only pending courses" do
    pending_course = Course.create!(@valid_attributes)
    approved_course = Course.create!(@valid_attributes.merge(
      status: "approved", github_owner: "other", github_repo: "approved-repo",
      github_repo_url: "https://github.com/other/approved-repo"
    ))

    result = Course.pending
    assert_includes result, pending_course
    assert_not_includes result, approved_course
  end

  test "validating scope returns only validating courses" do
    Course.create!(@valid_attributes)
    validating_course = Course.create!(@valid_attributes.merge(
      status: "validating", github_owner: "other", github_repo: "validating-repo",
      github_repo_url: "https://github.com/other/validating-repo"
    ))

    result = Course.validating
    assert_includes result, validating_course
    assert_equal 1, result.count
  end

  test "approved scope returns only approved courses" do
    Course.create!(@valid_attributes)
    approved_course = Course.create!(@valid_attributes.merge(
      status: "approved", github_owner: "other", github_repo: "approved-repo",
      github_repo_url: "https://github.com/other/approved-repo"
    ))

    result = Course.approved
    assert_includes result, approved_course
    assert_equal 1, result.count
  end

  test "failed scope returns only failed courses" do
    Course.create!(@valid_attributes)
    failed_course = Course.create!(@valid_attributes.merge(
      status: "failed", github_owner: "other", github_repo: "failed-repo",
      github_repo_url: "https://github.com/other/failed-repo"
    ))

    result = Course.failed
    assert_includes result, failed_course
    assert_equal 1, result.count
  end

  test "removed scope returns only removed courses" do
    Course.create!(@valid_attributes)
    removed_course = Course.create!(@valid_attributes.merge(
      status: "removed", github_owner: "other", github_repo: "removed-repo",
      github_repo_url: "https://github.com/other/removed-repo"
    ))

    result = Course.removed
    assert_includes result, removed_course
    assert_equal 1, result.count
  end

  test "publicly_visible scope returns only approved courses" do
    pending_course = Course.create!(@valid_attributes)
    approved_course = Course.create!(@valid_attributes.merge(
      status: "approved", github_owner: "visible", github_repo: "visible-repo",
      github_repo_url: "https://github.com/visible/visible-repo"
    ))
    failed_course = Course.create!(@valid_attributes.merge(
      status: "failed", github_owner: "hidden", github_repo: "hidden-repo",
      github_repo_url: "https://github.com/hidden/hidden-repo"
    ))

    result = Course.publicly_visible
    assert_includes result, approved_course
    assert_not_includes result, pending_course
    assert_not_includes result, failed_course
  end

  test "pending? returns true for pending status" do
    course = Course.new(status: "pending")
    assert course.pending?
  end

  test "pending? returns false for non-pending status" do
    course = Course.new(status: "approved")
    assert_not course.pending?
  end

  test "validating? returns true for validating status" do
    course = Course.new(status: "validating")
    assert course.validating?
  end

  test "approved? returns true for approved status" do
    course = Course.new(status: "approved")
    assert course.approved?
  end

  test "failed? returns true for failed status" do
    course = Course.new(status: "failed")
    assert course.failed?
  end

  test "removed? returns true for removed status" do
    course = Course.new(status: "removed")
    assert course.removed?
  end

  test "status query methods return false for non-matching statuses" do
    course = Course.new(status: "pending")
    assert_not course.validating?
    assert_not course.approved?
    assert_not course.failed?
    assert_not course.removed?
  end

  test "requires a user association" do
    course = Course.new(@valid_attributes.except(:user))
    assert_not course.valid?
    assert_includes course.errors[:user], "must exist"
  end
end
