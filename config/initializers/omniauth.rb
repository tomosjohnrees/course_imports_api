Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.application.credentials.dig(:github, :client_id),
    Rails.application.credentials.dig(:github, :client_secret),
    scope: "read:user"
end

OmniAuth.config.logger = Rails.logger
