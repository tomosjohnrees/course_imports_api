Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle("submissions/user", limit: 5, period: 1.hour) do |req|
  req.session["user_id"] if req.path == "/courses" && req.post?
end

Rack::Attack.throttle("requests/ip", limit: 20, period: 1.minute) do |req|
  req.ip
end

Rack::Attack.blocklist("ban/abusive_submitters") do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 1.hour, bantime: 24.hours) do
    req.path == "/courses" && req.post?
  end
end

Rack::Attack.throttled_responder = lambda do |_request|
  [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded. Please try again later.\n" ] ]
end

Rack::Attack.blocklisted_responder = lambda do |_request|
  [ 403, { "Content-Type" => "text/plain" }, [ "Your IP has been temporarily blocked due to excessive requests.\n" ] ]
end
