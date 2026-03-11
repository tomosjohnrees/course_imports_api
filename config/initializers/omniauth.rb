Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    ENV.fetch("GITHUB_CLIENT_ID") { Rails.application.credentials.dig(:github, :client_id) },
    ENV.fetch("GITHUB_CLIENT_SECRET") { Rails.application.credentials.dig(:github, :client_secret) },
    scope: "read:user"
end

OmniAuth.config.logger = Rails.logger
