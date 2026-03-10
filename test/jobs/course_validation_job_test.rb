require "test_helper"

class CourseValidationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionCable::TestHelper

  setup do
    @user = User.create!(github_id: "job-test-user", github_username: "jobtester", github_token: "ghp_test_token")
    @course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/owner/repo",
      github_owner: "owner",
      github_repo: "repo",
      title: "Test Course",
      status: "pending"
    )

    @fake_client = FakeValidationClient.new
    setup_valid_repo
  end

  test "approves course with metadata and records successful attempt" do
    run_validation

    @course.reload
    assert_equal "approved", @course.status
    assert_equal "my-course", @course.external_id
    assert_equal "My Course", @course.title
    assert_equal "A great course", @course.description
    assert_equal "1.0", @course.version
    assert_equal "Test Author", @course.author_name
    assert_equal [ "ruby", "rails" ], @course.tags
    assert_equal 2, @course.topic_count
    assert_not_nil @course.last_validated_at
    assert_nil @course.validation_error

    attempt = @course.validation_attempts.last
    assert_equal "success", attempt.result
    assert_nil attempt.error_message
    assert attempt.duration_ms >= 0
  end

  test "fails course with error and records failed attempt" do
    @fake_client.repo_metadata = { "private" => true, "archived" => false, "size" => 1000 }

    run_validation

    @course.reload
    assert_equal "failed", @course.status
    assert_equal "Repository is private", @course.validation_error

    attempt = @course.validation_attempts.last
    assert_equal "failure", attempt.result
    assert_equal "Repository is private", attempt.error_message
  end

  test "handles unexpected errors without leaking details" do
    @course.run_validation!(github_client: RaisingClient.new(RuntimeError, "secret detail\n/app/path:42"))

    @course.reload
    assert_equal "failed", @course.status
    assert_equal "An unexpected error occurred during validation", @course.validation_error

    attempt = @course.validation_attempts.last
    assert_equal "failure", attempt.result
    assert_equal 0, attempt.api_calls_made
  end

  test "handles timeout with specific error message" do
    @course.run_validation!(github_client: RaisingClient.new(Timeout::Error))

    @course.reload
    assert_equal "failed", @course.status
    assert_match(/timed out/, @course.validation_error)

    attempt = @course.validation_attempts.last
    assert_equal "failure", attempt.result
    assert_equal 30_000, attempt.duration_ms
  end

  test "broadcasts status update after validation" do
    assert_broadcasts "course_#{@course.id}", 1 do
      run_validation
    end
  end

  test "skips validation for non-pending and non-failed courses" do
    %i[validating approved removed].each do |status|
      @course.update!(status: status)
      run_validation
      assert_equal status.to_s, @course.reload.status
      assert_equal 0, @course.validation_attempts.count
    end
  end

  test "re-validates failed courses and clears previous error" do
    @course.update!(status: :failed, validation_error: "Previous error")

    run_validation

    @course.reload
    assert_equal "approved", @course.status
    assert_nil @course.validation_error
  end

  test "submit_for_validation! enqueues for pending and failed courses" do
    assert_enqueued_jobs 1 do
      @course.submit_for_validation!
    end

    @course.update!(status: :failed)
    assert_enqueued_jobs 1 do
      @course.submit_for_validation!
    end
  end

  test "submit_for_validation! rejects non-pending and non-failed courses" do
    %i[validating approved removed].each do |status|
      @course.update!(status: status)
      assert_no_enqueued_jobs do
        assert_equal false, @course.submit_for_validation!
      end
    end
  end

  private

  def setup_valid_repo
    @fake_client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @fake_client.files["course.json"] = stub_file({
      "id" => "my-course", "title" => "My Course", "description" => "A great course",
      "topicOrder" => [ "intro", "basics" ], "tags" => [ "ruby", "rails" ],
      "version" => "1.0", "author" => "Test Author"
    }.to_json)
    @fake_client.directories["topics"] = [
      { "name" => "intro", "type" => "dir" },
      { "name" => "basics", "type" => "dir" }
    ]
    @fake_client.files["topics/intro/content.json"] = stub_file([
      { "type" => "text", "content" => "Hello" },
      { "type" => "code", "content" => "puts 'hi'" }
    ].to_json)
  end

  def stub_file(content)
    { "type" => "file", "encoding" => "base64", "content" => Base64.encode64(content),
      "decoded_content" => content, "size" => content.bytesize }
  end

  def run_validation
    @course.run_validation!(github_client: @fake_client)
  end
end

class FakeValidationClient
  attr_accessor :repo_metadata, :files, :directories

  def initialize
    @repo_metadata = nil
    @files = {}
    @directories = {}
  end

  def fetch_repo_metadata(_owner, _repo) = @repo_metadata

  def fetch_file(_owner, _repo, path)
    raise GithubClient::NotFoundError, "#{path} not found" unless @files.key?(path)
    @files[path]
  end

  def fetch_directory(_owner, _repo, path)
    raise GithubClient::NotFoundError, "#{path} not found" unless @directories.key?(path)
    @directories[path]
  end
end

class RaisingClient
  def initialize(error_class, message = nil)
    @error_class = error_class
    @message = message
  end

  def fetch_repo_metadata(*, **) = raise(@error_class, @message)
  def fetch_file(*, **) = raise(@error_class, @message)
  def fetch_directory(*, **) = raise(@error_class, @message)
end
