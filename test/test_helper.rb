ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end

module OmniAuthTestHelper
  def mock_omniauth_github(uid: "12345", nickname: "octocat", name: "The Octocat",
                           image: "https://avatars.githubusercontent.com/u/12345",
                           token: "ghp_mock_token")
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      "provider" => "github",
      "uid" => uid,
      "info" => {
        "nickname" => nickname,
        "name" => name,
        "image" => image
      },
      "credentials" => {
        "token" => token
      }
    )
  end

  def mock_omniauth_failure
    OmniAuth.config.mock_auth[:github] = :invalid_credentials
  end

  def sign_in_as(user)
    mock_omniauth_github(
      uid: user.github_id,
      nickname: user.github_username,
      name: user.display_name,
      image: user.avatar_url
    )
    get "/auth/github/callback"
  end
end

class ActionDispatch::IntegrationTest
  include OmniAuthTestHelper
end
