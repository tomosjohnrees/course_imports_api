class CourseValidation
  MAX_REPO_SIZE_KB = 5_000
  MAX_TOPIC_COUNT = 50
  MAX_TITLE_LENGTH = 200
  MAX_DESCRIPTION_LENGTH = 2_000
  MAX_COURSE_JSON_KB = 50
  MAX_CONTENT_JSON_KB = 100
  MAX_BLOCKS_PER_TOPIC = 100
  MAX_TAGS = 10
  MAX_TAG_LENGTH = 50
  COURSE_ID_PATTERN = /\A[a-zA-Z0-9\-]+\z/

  Result = Data.define(:success?, :metadata, :error, :api_calls, :duration_ms)

  class ValidationError < StandardError; end

  def initialize(course:, github_client:)
    @course = course
    @client = github_client
    @owner = course.github_owner
    @repo = course.github_repo
    @api_calls = 0
    @start_time = nil
  end

  def call
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    validate_repo_metadata
    course_data = validate_course_json
    validate_topics_directory(course_data)
    metadata = validate_first_topic(course_data)

    success(metadata)
  rescue ValidationError => e
    failure(e.message)
  rescue GithubClient::NotFoundError
    failure("Repository not found or not accessible")
  rescue GithubClient::RateLimitedError
    failure("GitHub API rate limit exceeded — please try again later")
  rescue GithubClient::NetworkError
    failure("Could not reach GitHub — please try again later")
  end

  private

  def validate_repo_metadata
    @api_calls += 1
    repo = @client.fetch_repo_metadata(@owner, @repo)

    raise ValidationError, "Repository is private" if repo["private"]
    raise ValidationError, "Repository is archived" if repo["archived"]
    raise ValidationError, "Repository is too large (#{repo["size"]}KB, max #{MAX_REPO_SIZE_KB}KB)" if repo["size"].to_i > MAX_REPO_SIZE_KB
  end

  def validate_course_json
    @api_calls += 1
    file = @client.fetch_file(@owner, @repo, "course.json")

    raise ValidationError, "course.json is too large (max #{MAX_COURSE_JSON_KB}KB)" if file["size"].to_i > MAX_COURSE_JSON_KB * 1024

    data = parse_json(file["decoded_content"], "course.json")
    validate_required_course_fields(data)
    validate_course_field_lengths(data)
    validate_topic_order(data)

    data
  rescue GithubClient::NotFoundError
    raise ValidationError, "course.json not found in repository root"
  end

  def validate_topics_directory(course_data)
    @api_calls += 1
    entries = @client.fetch_directory(@owner, @repo, "topics")

    raise ValidationError, "Topics directory has too many entries (#{entries.size}, max #{MAX_TOPIC_COUNT})" if entries.size > MAX_TOPIC_COUNT

    dir_names = entries.select { |e| e["type"] == "dir" }.map { |e| e["name"] }
    topic_order = course_data["topicOrder"]

    missing = topic_order - dir_names
    raise ValidationError, "Topics directory is missing folders listed in topicOrder: #{missing.join(', ')}" if missing.any?
  rescue GithubClient::NotFoundError
    raise ValidationError, "Topics directory not found in repository"
  end

  def validate_first_topic(course_data)
    first_topic = course_data["topicOrder"].first

    @api_calls += 1
    file = @client.fetch_file(@owner, @repo, "topics/#{first_topic}/content.json")

    raise ValidationError, "content.json for topic '#{first_topic}' is too large (max #{MAX_CONTENT_JSON_KB}KB)" if file["size"].to_i > MAX_CONTENT_JSON_KB * 1024

    blocks = parse_json(file["decoded_content"], "topics/#{first_topic}/content.json")

    raise ValidationError, "content.json for topic '#{first_topic}' must be a JSON array" unless blocks.is_a?(Array)
    raise ValidationError, "content.json for topic '#{first_topic}' must contain at least one block" if blocks.empty?
    raise ValidationError, "content.json for topic '#{first_topic}' has too many blocks (#{blocks.size}, max #{MAX_BLOCKS_PER_TOPIC})" if blocks.size > MAX_BLOCKS_PER_TOPIC

    blocks.each_with_index do |block, i|
      raise ValidationError, "Block #{i} in topic '#{first_topic}' is missing a 'type' field" unless block.is_a?(Hash) && block.key?("type")
    end

    extract_metadata(course_data)
  rescue GithubClient::NotFoundError
    raise ValidationError, "content.json not found for topic '#{first_topic}'"
  end

  def validate_required_course_fields(data)
    %w[id title description topicOrder].each do |field|
      raise ValidationError, "course.json is missing required field '#{field}'" unless data.key?(field)
    end
  end

  def validate_course_field_lengths(data)
    raise ValidationError, "Title exceeds #{MAX_TITLE_LENGTH} characters" if data["title"].to_s.length > MAX_TITLE_LENGTH
    raise ValidationError, "Description exceeds #{MAX_DESCRIPTION_LENGTH} characters" if data["description"].to_s.length > MAX_DESCRIPTION_LENGTH
    raise ValidationError, "Course ID contains invalid characters" unless data["id"].to_s.match?(COURSE_ID_PATTERN)
  end

  def validate_topic_order(data)
    topic_order = data["topicOrder"]
    raise ValidationError, "topicOrder must be an array" unless topic_order.is_a?(Array)
    raise ValidationError, "topicOrder must contain at least one topic" if topic_order.empty?
    raise ValidationError, "topicOrder has too many entries (#{topic_order.size}, max #{MAX_TOPIC_COUNT})" if topic_order.size > MAX_TOPIC_COUNT
  end

  def extract_metadata(course_data)
    tags = Array(course_data["tags"]).first(MAX_TAGS).map { |t| t.to_s.truncate(MAX_TAG_LENGTH) }

    {
      course_id: course_data["id"].to_s.truncate(MAX_TITLE_LENGTH),
      title: course_data["title"].to_s.truncate(MAX_TITLE_LENGTH),
      description: course_data["description"].to_s.truncate(MAX_DESCRIPTION_LENGTH),
      tags: tags,
      topic_count: Array(course_data["topicOrder"]).size,
      version: course_data["version"].to_s.truncate(50),
      author: course_data["author"].to_s.truncate(200)
    }
  end

  def parse_json(content, filename)
    JSON.parse(content)
  rescue JSON::ParserError
    raise ValidationError, "#{filename} contains invalid JSON"
  end

  def elapsed_ms
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time) * 1000).round
  end

  def success(metadata)
    Result.new(success?: true, metadata: metadata, error: nil, api_calls: @api_calls, duration_ms: elapsed_ms)
  end

  def failure(error)
    Result.new(success?: false, metadata: nil, error: error, api_calls: @api_calls, duration_ms: elapsed_ms)
  end
end
