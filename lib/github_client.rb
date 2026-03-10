class GithubClient
  BASE_URL = "https://api.github.com"
  TIMEOUT = 5

  class Error < StandardError; end
  class NotFoundError < Error; end
  class RateLimitedError < Error; end
  class NetworkError < Error; end

  def initialize(token: nil)
    @token = token
  end

  def fetch_repo_metadata(owner, repo)
    get("/repos/#{owner}/#{repo}")
  end

  def fetch_file(owner, repo, path)
    response = get("/repos/#{owner}/#{repo}/contents/#{path}")

    if response["type"] == "file" && response["encoding"] == "base64"
      response.merge("decoded_content" => Base64.decode64(response["content"]))
    else
      response
    end
  end

  def fetch_directory(owner, repo, path)
    response = get("/repos/#{owner}/#{repo}/contents/#{path}")

    raise Error, "Expected directory listing but got #{response["type"]}" unless response.is_a?(Array)

    response
  end

  private

  def get(path)
    response = connection.get(path)
    response.body
  rescue Faraday::ResourceNotFound
    raise NotFoundError, "GitHub resource not found: #{path}"
  rescue Faraday::ForbiddenError
    raise RateLimitedError, "GitHub API rate limit exceeded"
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise NetworkError, "GitHub API network error: #{e.message}"
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :authorization, "Bearer", @token if @token
      f.response :raise_error
      f.response :json
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
    end
  end
end
