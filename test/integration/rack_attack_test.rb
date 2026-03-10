require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "ra001",
      github_username: "ratelimituser",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_rate_limit_token"
    )

    Rack::Attack.cache.store.clear
    Rack::Attack.reset!
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
    Rack::Attack.cache.store.clear
    Rack::Attack.reset!
  end

  test "allows up to 5 course submissions per user per hour" do
    sign_in_as(@user)

    5.times do |i|
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/repo-#{i}" } }
      assert_includes [ 302, 422 ], response.status,
        "Request #{i + 1} should be allowed (got #{response.status})"
    end
  end

  test "throttles course submissions after 5 per user per hour" do
    sign_in_as(@user)

    6.times do |i|
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/throttle-#{i}" } }
    end

    assert_equal 429, response.status
    assert_equal "Rate limit exceeded. Please try again later.\n", response.body
  end

  test "submission throttle does not count GET requests" do
    sign_in_as(@user)

    10.times { get new_course_path }

    post courses_path, params: { course: { github_repo_url: "https://github.com/owner/get-no-count" } }
    assert_includes [ 302, 422 ], response.status,
      "POST should still be allowed after GET requests (got #{response.status})"
  end

  test "allows up to 20 requests per IP per minute" do
    20.times { get root_path }

    assert_response :success
  end

  test "throttles after 20 requests per IP per minute" do
    21.times { get root_path }

    assert_equal 429, response.status
    assert_equal "text/plain", response.content_type
    assert_equal "Rate limit exceeded. Please try again later.\n", response.body
  end

  test "blocks IP after 10 POST requests to /courses in an hour" do
    sign_in_as(@user)

    11.times do |i|
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/ban-#{i}" } }
    end

    assert_equal 403, response.status
    assert_equal "text/plain", response.content_type
    assert_equal "Your IP has been temporarily blocked due to excessive requests.\n", response.body
  end

  test "blocked IP receives 403 on subsequent requests" do
    sign_in_as(@user)

    11.times do |i|
      post courses_path, params: { course: { github_repo_url: "https://github.com/owner/block-#{i}" } }
    end
    assert_equal 403, response.status

    get root_path
    assert_equal 403, response.status
  end

  test "blocklist only counts POST requests to /courses" do
    sign_in_as(@user)

    15.times { get new_course_path }
    Rack::Attack.cache.store.clear

    get root_path
    assert_response :success
  end
end
