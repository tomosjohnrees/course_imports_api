require "test_helper"

class ValidationAttemptTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(github_id: "va-model-test", github_username: "vamodeltester")
    @course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/vamodel/test",
      github_owner: "vamodel",
      github_repo: "test",
      title: "VA Model Test",
      status: "pending"
    )
  end

  test "valid validation attempt with course association" do
    attempt = ValidationAttempt.new(course: @course)
    assert attempt.valid?
  end

  test "belongs to course" do
    attempt = ValidationAttempt.create!(course: @course, result: "passed")
    assert_equal @course, attempt.course
  end

  test "requires a course association" do
    attempt = ValidationAttempt.new(course: nil)
    assert_not attempt.valid?
    assert_includes attempt.errors[:course], "must exist"
  end

  test "stores result string" do
    attempt = ValidationAttempt.create!(course: @course, result: "passed")
    assert_equal "passed", attempt.reload.result
  end

  test "stores error_message text" do
    attempt = ValidationAttempt.create!(course: @course, result: "failed", error_message: "Missing manifest.json")
    assert_equal "Missing manifest.json", attempt.reload.error_message
  end

  test "stores api_calls_made integer" do
    attempt = ValidationAttempt.create!(course: @course, api_calls_made: 6)
    assert_equal 6, attempt.reload.api_calls_made
  end

  test "stores duration_ms integer" do
    attempt = ValidationAttempt.create!(course: @course, duration_ms: 1200)
    assert_equal 1200, attempt.reload.duration_ms
  end

  test "allows nullable fields" do
    attempt = ValidationAttempt.create!(course: @course)
    attempt.reload
    assert_nil attempt.result
    assert_nil attempt.error_message
    assert_nil attempt.api_calls_made
    assert_nil attempt.duration_ms
  end
end
