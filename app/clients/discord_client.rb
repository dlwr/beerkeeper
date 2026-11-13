require "net/http"

class DiscordClient
  class Error < StandardError
    attr_reader :code

    def initialize(message = nil, code: nil)
      super(message)
      @code = code
    end
  end

  class RateLimited < Error
    attr_reader :retry_after

    def initialize(message = nil, retry_after:)
      super(message)
      @retry_after = retry_after
    end
  end

  API_BASE = "https://discord.com/api/v10"
  AUTHORIZE_URL = "https://discord.com/oauth2/authorize"
  SCOPES = "identify guilds.join"
  REQUIRED_ENV = %w[DISCORD_CLIENT_ID DISCORD_CLIENT_SECRET DISCORD_BOT_TOKEN DISCORD_GUILD_ID].freeze

  class << self
    def configured?
      REQUIRED_ENV.all? { |key| ENV[key].present? }
    end

    def authorize_url(redirect_uri:, state:)
      query = {
        client_id: ENV.fetch("DISCORD_CLIENT_ID"),
        response_type: "code",
        scope: SCOPES,
        state:,
        redirect_uri:
      }
      "#{AUTHORIZE_URL}?#{URI.encode_www_form(query)}"
    end

    def exchange_code(code:, redirect_uri:)
      request = Net::HTTP::Post.new(uri("/oauth2/token"))
      request.set_form_data(
        client_id: ENV.fetch("DISCORD_CLIENT_ID"),
        client_secret: ENV.fetch("DISCORD_CLIENT_SECRET"),
        grant_type: "authorization_code",
        code:,
        redirect_uri:
      )
      perform(request)["access_token"].presence || raise(Error, "Discord API returned no access token")
    end

    def fetch_user(access_token)
      request = Net::HTTP::Get.new(uri("/users/@me"))
      request["Authorization"] = "Bearer #{access_token}"
      user = perform(request)
      raise Error, "Discord API returned no user id" if user["id"].blank?

      user.slice("id", "username", "global_name", "avatar")
    end

    def add_guild_member(user_id:, access_token:)
      bot_request(Net::HTTP::Put, "/guilds/#{ENV.fetch("DISCORD_GUILD_ID")}/members/#{user_id}", { access_token: })
    end

    def send_dm(user_id:, content:)
      channel = bot_request(Net::HTTP::Post, "/users/@me/channels", { recipient_id: user_id })
      bot_request(Net::HTTP::Post, "/channels/#{channel.fetch("id")}/messages", { content:, allowed_mentions: { parse: [] } })
    rescue KeyError
      raise Error, "Discord API returned no DM channel"
    end

    private

    def bot_request(request_class, path, payload)
      request = request_class.new(uri(path))
      request["Authorization"] = "Bot #{ENV.fetch("DISCORD_BOT_TOKEN")}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json
      perform(request)
    end

    def uri(path)
      URI("#{API_BASE}#{path}")
    end

    def perform(request)
      request["User-Agent"] = "DiscordBot (https://beerkeeper.yuta25.com, 1.0)"
      target = request.uri
      response = Net::HTTP.start(target.host, target.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
      body = response.body.present? ? JSON.parse(response.body) : {}
      return body if response.is_a?(Net::HTTPSuccess)

      details = body.is_a?(Hash) ? body : {}
      message = "Discord API #{request.method} #{target.path} returned #{response.code}"
      raise RateLimited.new(message, retry_after: details["retry_after"].to_f) if response.code == "429"

      raise Error.new(message, code: details["code"])
    rescue JSON::ParserError
      raise Error, "Discord API #{request.method} #{request.uri&.path} returned #{response&.code} with invalid JSON"
    rescue Net::OpenTimeout, Net::ReadTimeout, SystemCallError, SocketError => e
      raise Error, "Discord API #{request.method} #{request.uri&.path} failed: #{e.class}"
    end
  end
end
