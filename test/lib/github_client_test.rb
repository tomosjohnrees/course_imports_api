require "test_helper"

class GithubClientTest < ActiveSupport::TestCase
  setup do
    @stubs = Faraday::Adapter::Test::Stubs.new
    @client = GithubClient.new(token: "ghp_test_token")
    inject_test_adapter(@client, @stubs)
  end

  teardown do
    @stubs.verify_stubbed_calls
  end

  test "fetch_repo_metadata returns parsed repo data" do
    repo_data = { "id" => 1, "full_name" => "owner/repo", "private" => false, "description" => "A test repo" }
    @stubs.get("/repos/owner/repo") { [ 200, { "Content-Type" => "application/json" }, repo_data.to_json ] }

    result = @client.fetch_repo_metadata("owner", "repo")

    assert_equal "owner/repo", result["full_name"]
    assert_equal false, result["private"]
    assert_equal "A test repo", result["description"]
  end

  test "fetch_file decodes base64 file contents" do
    content = "# My Course\n\nWelcome!"
    encoded = Base64.encode64(content)
    file_data = { "type" => "file", "encoding" => "base64", "content" => encoded, "name" => "README.md" }
    @stubs.get("/repos/owner/repo/contents/README.md") { [ 200, { "Content-Type" => "application/json" }, file_data.to_json ] }

    result = @client.fetch_file("owner", "repo", "README.md")

    assert_equal content, result["decoded_content"]
    assert_equal "README.md", result["name"]
  end

  test "fetch_file returns raw response for non-base64 files" do
    file_data = { "type" => "file", "encoding" => "none", "content" => "raw content" }
    @stubs.get("/repos/owner/repo/contents/file.txt") { [ 200, { "Content-Type" => "application/json" }, file_data.to_json ] }

    result = @client.fetch_file("owner", "repo", "file.txt")

    assert_nil result["decoded_content"]
  end

  test "fetch_directory returns list of entries" do
    entries = [
      { "name" => "README.md", "type" => "file" },
      { "name" => "src", "type" => "dir" }
    ]
    @stubs.get("/repos/owner/repo/contents/") { [ 200, { "Content-Type" => "application/json" }, entries.to_json ] }

    result = @client.fetch_directory("owner", "repo", "")

    assert_equal 2, result.length
    assert_equal "README.md", result[0]["name"]
  end

  test "fetch_directory raises when response is not an array" do
    file_data = { "type" => "file", "name" => "README.md" }
    @stubs.get("/repos/owner/repo/contents/README.md") { [ 200, { "Content-Type" => "application/json" }, file_data.to_json ] }

    assert_raises(GithubClient::Error) do
      @client.fetch_directory("owner", "repo", "README.md")
    end
  end

  test "raises NotFoundError on 404" do
    @stubs.get("/repos/owner/nonexistent") { [ 404, {}, "" ] }

    assert_raises(GithubClient::NotFoundError) do
      @client.fetch_repo_metadata("owner", "nonexistent")
    end
  end

  test "raises RateLimitedError on 403" do
    @stubs.get("/repos/owner/repo") { [ 403, {}, "" ] }

    assert_raises(GithubClient::RateLimitedError) do
      @client.fetch_repo_metadata("owner", "repo")
    end
  end

  test "raises NetworkError on timeout" do
    @stubs.get("/repos/owner/repo") { raise Faraday::TimeoutError }

    assert_raises(GithubClient::NetworkError) do
      @client.fetch_repo_metadata("owner", "repo")
    end
  end

  test "raises NetworkError on connection failure" do
    @stubs.get("/repos/owner/repo") { raise Faraday::ConnectionFailed, "connection refused" }

    assert_raises(GithubClient::NetworkError) do
      @client.fetch_repo_metadata("owner", "repo")
    end
  end

  test "includes bearer token when provided" do
    @stubs.get("/repos/owner/repo") do |env|
      assert_equal "Bearer ghp_test_token", env.request_headers["Authorization"]
      [ 200, { "Content-Type" => "application/json" }, { "id" => 1 }.to_json ]
    end

    @client.fetch_repo_metadata("owner", "repo")
  end

  test "omits authorization header without a token" do
    unauthenticated_stubs = Faraday::Adapter::Test::Stubs.new
    unauthenticated_client = GithubClient.new
    inject_test_adapter(unauthenticated_client, unauthenticated_stubs)

    unauthenticated_stubs.get("/repos/owner/repo") do |env|
      assert_nil env.request_headers["Authorization"]
      [ 200, { "Content-Type" => "application/json" }, { "id" => 1 }.to_json ]
    end

    unauthenticated_client.fetch_repo_metadata("owner", "repo")
    unauthenticated_stubs.verify_stubbed_calls
  end

  private

  def inject_test_adapter(client, stubs)
    token = client.instance_variable_get(:@token)
    connection = Faraday.new(url: GithubClient::BASE_URL) do |f|
      f.request :authorization, "Bearer", token if token
      f.response :raise_error
      f.response :json
      f.adapter :test, stubs
    end
    client.instance_variable_set(:@connection, connection)
  end
end
