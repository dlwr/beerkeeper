module LoginHelpers
  def log_in(user)
    with_env(DiscordHelpers::DISCORD_ENV) do
      stub_request(:post, "https://discord.com/api/v10/oauth2/token")
        .to_return(status: 200, body: { access_token: "user-token" }.to_json)
      stub_request(:get, "https://discord.com/api/v10/users/@me")
        .to_return(status: 200, body: { id: user.discord_user_id, username: user.name, avatar: user.discord_avatar }.to_json)
      stub_request(:put, "https://discord.com/api/v10/guilds/guild-id/members/#{user.discord_user_id}")
        .to_return(status: 201, body: "{}")

      post discord_login_path
      state = Rack::Utils.parse_query(URI.parse(response.location).query).fetch("state")
      get discord_callback_path, params: { code: "the-code", state: }
    end
  end
end

RSpec.configure do |config|
  config.include LoginHelpers, type: :request
end
