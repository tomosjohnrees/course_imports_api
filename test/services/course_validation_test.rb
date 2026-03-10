require "test_helper"

class CourseValidationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(github_id: "validation-svc-user", github_username: "validator")
    @course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/owner/repo",
      github_owner: "owner",
      github_repo: "repo",
      title: "Test Course",
      status: "pending"
    )

    @valid_course_json = {
      "id" => "my-course",
      "title" => "My Course",
      "description" => "A great course",
      "topicOrder" => [ "intro", "basics" ],
      "tags" => [ "ruby", "rails" ],
      "version" => "1.0",
      "author" => "Test Author"
    }

    @valid_content_json = [
      { "type" => "text", "content" => "Hello" },
      { "type" => "code", "content" => "puts 'hi'" }
    ]

    @client = FakeGithubClient.new
  end

  def build_service
    CourseValidation.new(course: @course, github_client: @client)
  end

  def stub_file(content, size: nil)
    {
      "type" => "file",
      "encoding" => "base64",
      "content" => Base64.encode64(content),
      "decoded_content" => content,
      "size" => size || content.bytesize
    }
  end

  def stub_topics_directory(names)
    names.map { |n| { "name" => n, "type" => "dir" } }
  end

  def setup_valid_repo
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json)
    @client.directories["topics"] = stub_topics_directory([ "intro", "basics" ])
    @client.files["topics/intro/content.json"] = stub_file(@valid_content_json.to_json)
  end

  test "happy path: valid repo passes all four validation steps" do
    setup_valid_repo
    result = build_service.call

    assert result.success?
    assert_nil result.error
    assert_equal 4, result.api_calls
    assert result.duration_ms >= 0

    metadata = result.metadata
    assert_equal "my-course", metadata[:course_id]
    assert_equal "My Course", metadata[:title]
    assert_equal "A great course", metadata[:description]
    assert_equal [ "ruby", "rails" ], metadata[:tags]
    assert_equal 2, metadata[:topic_count]
    assert_equal "1.0", metadata[:version]
    assert_equal "Test Author", metadata[:author]
  end

  test "result includes api_calls count" do
    setup_valid_repo
    result = build_service.call
    assert_equal 4, result.api_calls
  end

  test "result includes duration_ms" do
    setup_valid_repo
    result = build_service.call
    assert_kind_of Integer, result.duration_ms
    assert result.duration_ms >= 0
  end

  test "step 1: rejects private repository" do
    @client.repo_metadata = { "private" => true, "archived" => false, "size" => 1000 }
    result = build_service.call

    assert_not result.success?
    assert_equal "Repository is private", result.error
    assert_equal 1, result.api_calls
  end

  test "step 1: rejects archived repository" do
    @client.repo_metadata = { "private" => false, "archived" => true, "size" => 1000 }
    result = build_service.call

    assert_not result.success?
    assert_equal "Repository is archived", result.error
    assert_equal 1, result.api_calls
  end

  test "step 1: rejects oversized repository" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 6000 }
    result = build_service.call

    assert_not result.success?
    assert_match(/too large/, result.error)
    assert_equal 1, result.api_calls
  end

  test "step 1: accepts repository at exact size limit" do
    setup_valid_repo
    @client.repo_metadata["size"] = 5000
    result = build_service.call

    assert result.success?
  end

  test "step 1: handles NotFoundError from GitHub" do
    @client.repo_metadata_error = GithubClient::NotFoundError
    result = build_service.call

    assert_not result.success?
    assert_equal "Repository not found or not accessible", result.error
  end

  test "step 1: handles RateLimitedError from GitHub" do
    @client.repo_metadata_error = GithubClient::RateLimitedError
    result = build_service.call

    assert_not result.success?
    assert_match(/rate limit/, result.error)
  end

  test "step 1: handles NetworkError from GitHub" do
    @client.repo_metadata_error = GithubClient::NetworkError
    result = build_service.call

    assert_not result.success?
    assert_match(/Could not reach GitHub/, result.error)
  end

  test "step 2: rejects missing course.json" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    result = build_service.call

    assert_not result.success?
    assert_equal "course.json not found in repository root", result.error
    assert_equal 2, result.api_calls
  end

  test "step 2: rejects course.json with invalid JSON" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file("not valid json")
    result = build_service.call

    assert_not result.success?
    assert_equal "course.json contains invalid JSON", result.error
  end

  test "step 2: rejects course.json that is too large" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json, size: 51 * 1024)
    result = build_service.call

    assert_not result.success?
    assert_match(/course\.json is too large/, result.error)
  end

  test "step 2: rejects course.json missing 'id' field" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.except("id").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "course.json is missing required field 'id'", result.error
  end

  test "step 2: rejects course.json missing 'title' field" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.except("title").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "course.json is missing required field 'title'", result.error
  end

  test "step 2: rejects course.json missing 'description' field" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.except("description").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "course.json is missing required field 'description'", result.error
  end

  test "step 2: rejects course.json missing 'topicOrder' field" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.except("topicOrder").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "course.json is missing required field 'topicOrder'", result.error
  end

  test "step 2: rejects title exceeding max length" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("title" => "x" * 201).to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/Title exceeds/, result.error)
  end

  test "step 2: accepts title at exact max length" do
    setup_valid_repo
    @client.files["course.json"] = stub_file(@valid_course_json.merge("title" => "x" * 200).to_json)
    result = build_service.call

    assert result.success?
  end

  test "step 2: rejects description exceeding max length" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("description" => "x" * 2001).to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/Description exceeds/, result.error)
  end

  test "step 2: rejects course ID with invalid characters" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("id" => "invalid id!").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "Course ID contains invalid characters", result.error
  end

  test "step 2: accepts course ID with alphanumeric and hyphens" do
    setup_valid_repo
    @client.files["course.json"] = stub_file(@valid_course_json.merge("id" => "my-Course-123").to_json)
    result = build_service.call

    assert result.success?
  end

  test "step 2: rejects topicOrder that is not an array" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("topicOrder" => "not-an-array").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "topicOrder must be an array", result.error
  end

  test "step 2: rejects empty topicOrder" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("topicOrder" => []).to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "topicOrder must contain at least one topic", result.error
  end

  test "step 2: rejects topicOrder exceeding max entries" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    topics = (1..51).map { |i| "topic-#{i}" }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("topicOrder" => topics).to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/topicOrder has too many entries/, result.error)
  end

  test "step 3: rejects missing topics directory" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "Topics directory not found in repository", result.error
    assert_equal 3, result.api_calls
  end

  test "step 3: rejects topics directory with too many entries" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json)
    @client.directories["topics"] = (1..51).map { |i| { "name" => "topic-#{i}", "type" => "dir" } }
    result = build_service.call

    assert_not result.success?
    assert_match(/too many entries/, result.error)
  end

  test "step 3: rejects when topicOrder lists folders not present in topics directory" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json)
    @client.directories["topics"] = stub_topics_directory([ "intro" ])
    result = build_service.call

    assert_not result.success?
    assert_match(/missing folders listed in topicOrder: basics/, result.error)
  end

  test "step 3: allows extra directories not listed in topicOrder" do
    setup_valid_repo
    @client.directories["topics"] = stub_topics_directory([ "intro", "basics", "extra-topic" ])
    result = build_service.call

    assert result.success?
  end

  test "step 3: ignores file entries in topics directory" do
    setup_valid_repo
    @client.directories["topics"] = [
      { "name" => "intro", "type" => "dir" },
      { "name" => "basics", "type" => "dir" },
      { "name" => "README.md", "type" => "file" }
    ]
    result = build_service.call

    assert result.success?
  end

  test "step 4: rejects missing content.json for first topic" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json)
    @client.directories["topics"] = stub_topics_directory([ "intro", "basics" ])
    result = build_service.call

    assert_not result.success?
    assert_match(/content\.json not found for topic 'intro'/, result.error)
    assert_equal 4, result.api_calls
  end

  test "step 4: rejects content.json that is too large" do
    setup_valid_repo
    @client.files["topics/intro/content.json"] = stub_file(@valid_content_json.to_json, size: 101 * 1024)
    result = build_service.call

    assert_not result.success?
    assert_match(/content\.json for topic 'intro' is too large/, result.error)
  end

  test "step 4: rejects content.json with invalid JSON" do
    setup_valid_repo
    @client.files["topics/intro/content.json"] = stub_file("not valid json")
    result = build_service.call

    assert_not result.success?
    assert_match(/contains invalid JSON/, result.error)
  end

  test "step 4: rejects content.json that is not an array" do
    setup_valid_repo
    @client.files["topics/intro/content.json"] = stub_file({ "type" => "text" }.to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/must be a JSON array/, result.error)
  end

  test "step 4: rejects empty content.json array" do
    setup_valid_repo
    @client.files["topics/intro/content.json"] = stub_file([].to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/must contain at least one block/, result.error)
  end

  test "step 4: rejects content.json with too many blocks" do
    setup_valid_repo
    blocks = (1..101).map { |i| { "type" => "text", "content" => "block #{i}" } }
    @client.files["topics/intro/content.json"] = stub_file(blocks.to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/too many blocks/, result.error)
  end

  test "step 4: rejects block missing 'type' field" do
    setup_valid_repo
    @client.files["topics/intro/content.json"] = stub_file([ { "content" => "no type" } ].to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/Block 0.*missing a 'type' field/, result.error)
  end

  test "step 4: rejects block that is not a hash" do
    setup_valid_repo
    @client.files["topics/intro/content.json"] = stub_file([ "not a hash" ].to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/Block 0.*missing a 'type' field/, result.error)
  end

  test "step 4: validates first topic only (not second)" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    course_data = @valid_course_json.merge("topicOrder" => [ "intro", "advanced" ])
    @client.files["course.json"] = stub_file(course_data.to_json)
    @client.directories["topics"] = stub_topics_directory([ "intro", "advanced" ])
    @client.files["topics/intro/content.json"] = stub_file(@valid_content_json.to_json)
    result = build_service.call

    assert result.success?
    assert_equal 4, result.api_calls
  end

  test "validation stops at first failure and does not make unnecessary API calls" do
    @client.repo_metadata = { "private" => true, "archived" => false, "size" => 1000 }
    result = build_service.call

    assert_not result.success?
    assert_equal 1, result.api_calls
    assert_equal 0, @client.call_counts[:fetch_file]
    assert_equal 0, @client.call_counts[:fetch_directory]
  end

  test "step 2 failure stops after 2 API calls" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.except("id").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal 2, result.api_calls
    assert_equal 0, @client.call_counts[:fetch_directory]
  end

  test "step 3 failure stops after 3 API calls" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal 3, result.api_calls
  end

  test "metadata extraction truncates long tags" do
    setup_valid_repo
    long_tags = [ "a" * 100, "normal" ]
    @client.files["course.json"] = stub_file(@valid_course_json.merge("tags" => long_tags).to_json)
    result = build_service.call

    assert result.success?
    assert_equal 50, result.metadata[:tags].first.length
    assert_equal "normal", result.metadata[:tags].last
  end

  test "metadata extraction limits tags to MAX_TAGS" do
    setup_valid_repo
    many_tags = (1..15).map { |i| "tag-#{i}" }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("tags" => many_tags).to_json)
    result = build_service.call

    assert result.success?
    assert_equal 10, result.metadata[:tags].size
  end

  test "metadata extraction handles missing optional fields gracefully" do
    minimal_course = {
      "id" => "minimal",
      "title" => "Minimal Course",
      "description" => "Desc",
      "topicOrder" => [ "intro" ]
    }
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(minimal_course.to_json)
    @client.directories["topics"] = stub_topics_directory([ "intro" ])
    @client.files["topics/intro/content.json"] = stub_file(@valid_content_json.to_json)
    result = build_service.call

    assert result.success?
    assert_equal [], result.metadata[:tags]
    assert_equal "", result.metadata[:version]
    assert_equal "", result.metadata[:author]
  end

  test "Result data object has expected attributes" do
    setup_valid_repo
    result = build_service.call

    assert_respond_to result, :success?
    assert_respond_to result, :metadata
    assert_respond_to result, :error
    assert_respond_to result, :api_calls
    assert_respond_to result, :duration_ms
  end

  test "failure result has nil metadata" do
    @client.repo_metadata = { "private" => true, "archived" => false, "size" => 1000 }
    result = build_service.call

    assert_nil result.metadata
  end

  test "success result has nil error" do
    setup_valid_repo
    result = build_service.call

    assert_nil result.error
  end

  test "uses course github_owner and github_repo for API calls" do
    custom_course = Course.create!(
      user: @user,
      github_repo_url: "https://github.com/custom-org/custom-repo",
      github_owner: "custom-org",
      github_repo: "custom-repo",
      title: "Custom Course",
      status: "pending"
    )

    client = FakeGithubClient.new
    client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    client.files["course.json"] = stub_file(@valid_course_json.to_json)
    client.directories["topics"] = stub_topics_directory([ "intro", "basics" ])
    client.files["topics/intro/content.json"] = stub_file(@valid_content_json.to_json)

    service = CourseValidation.new(course: custom_course, github_client: client)
    result = service.call

    assert result.success?
    assert_equal [ "custom-org", "custom-repo" ], client.recorded_calls[:fetch_repo_metadata].first
  end

  test "step 2: rejects course ID with spaces" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("id" => "has spaces").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "Course ID contains invalid characters", result.error
  end

  test "step 2: rejects course ID with special characters" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file(@valid_course_json.merge("id" => "invalid@id!").to_json)
    result = build_service.call

    assert_not result.success?
    assert_equal "Course ID contains invalid characters", result.error
  end

  test "step 4: detects missing type on non-first block" do
    setup_valid_repo
    blocks = [ { "type" => "text" }, { "content" => "missing type" } ]
    @client.files["topics/intro/content.json"] = stub_file(blocks.to_json)
    result = build_service.call

    assert_not result.success?
    assert_match(/Block 1.*missing a 'type' field/, result.error)
  end

  test "step 1: checks private before archived" do
    @client.repo_metadata = { "private" => true, "archived" => true, "size" => 6000 }
    result = build_service.call

    assert_equal "Repository is private", result.error
  end

  test "step 1: checks archived before size" do
    @client.repo_metadata = { "private" => false, "archived" => true, "size" => 6000 }
    result = build_service.call

    assert_equal "Repository is archived", result.error
  end

  test "step 2: checks file size before parsing JSON" do
    @client.repo_metadata = { "private" => false, "archived" => false, "size" => 1000 }
    @client.files["course.json"] = stub_file("not json but doesnt matter", size: 51 * 1024)
    result = build_service.call

    assert_match(/course\.json is too large/, result.error)
  end

  test "step 4: accepts content.json at exact block limit" do
    setup_valid_repo
    blocks = (1..100).map { |i| { "type" => "text", "content" => "block #{i}" } }
    @client.files["topics/intro/content.json"] = stub_file(blocks.to_json)
    result = build_service.call

    assert result.success?
  end
end

class FakeGithubClient
  attr_accessor :repo_metadata, :repo_metadata_error, :files, :directories,
                :call_counts, :recorded_calls

  def initialize
    @repo_metadata = nil
    @repo_metadata_error = nil
    @files = {}
    @directories = {}
    @call_counts = Hash.new(0)
    @recorded_calls = Hash.new { |h, k| h[k] = [] }
  end

  def fetch_repo_metadata(owner, repo)
    @call_counts[:fetch_repo_metadata] += 1
    @recorded_calls[:fetch_repo_metadata] << [ owner, repo ]
    raise @repo_metadata_error if @repo_metadata_error
    @repo_metadata
  end

  def fetch_file(owner, repo, path)
    @call_counts[:fetch_file] += 1
    @recorded_calls[:fetch_file] << [ owner, repo, path ]
    raise GithubClient::NotFoundError, "#{path} not found" unless @files.key?(path)
    @files[path]
  end

  def fetch_directory(owner, repo, path)
    @call_counts[:fetch_directory] += 1
    @recorded_calls[:fetch_directory] << [ owner, repo, path ]
    raise GithubClient::NotFoundError, "#{path} not found" unless @directories.key?(path)
    @directories[path]
  end
end
