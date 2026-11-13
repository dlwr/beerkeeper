require "rails_helper"

RSpec.describe DiscordClient, :discord do
  describe ".configured?" do
    it "4 つのシークレットがそろっていれば true" do
      expect(described_class).to be_configured
    end

    it "どれかが欠けていれば false" do
      ENV["DISCORD_GUILD_ID"] = nil

      expect(described_class).not_to be_configured
    end
  end

  describe ".authorize_url" do
    it "identify と guilds.join のスコープで認可画面の URL を作る" do
      uri = URI.parse(described_class.authorize_url(redirect_uri: "http://www.example.com/auth/discord/callback", state: "abc"))
      query = Rack::Utils.parse_query(uri.query)

      expect(uri.host).to eq "discord.com"
      expect(uri.path).to eq "/oauth2/authorize"
      expect(query).to include(
        "client_id" => "client-id",
        "response_type" => "code",
        "scope" => "identify guilds.join",
        "state" => "abc",
        "redirect_uri" => "http://www.example.com/auth/discord/callback"
      )
    end
  end

  describe ".exchange_code" do
    it "認可コードをアクセストークンに換える" do
      stub = stub_request(:post, "https://discord.com/api/v10/oauth2/token")
        .with(
          body: {
            client_id: "client-id",
            client_secret: "client-secret",
            grant_type: "authorization_code",
            code: "the-code",
            redirect_uri: "http://www.example.com/auth/discord/callback"
          }
        )
        .to_return(status: 200, body: { access_token: "user-token", token_type: "Bearer" }.to_json, headers: { "Content-Type" => "application/json" })

      token = described_class.exchange_code(code: "the-code", redirect_uri: "http://www.example.com/auth/discord/callback")

      expect(token).to eq "user-token"
      expect(stub).to have_been_requested.once
    end

    it "失敗したら DiscordClient::Error を投げる" do
      stub_request(:post, "https://discord.com/api/v10/oauth2/token").to_return(status: 400, body: { error: "invalid_grant" }.to_json)

      expect {
        described_class.exchange_code(code: "bad", redirect_uri: "http://www.example.com/auth/discord/callback")
      }.to raise_error(DiscordClient::Error)
    end
  end

  describe ".fetch_user" do
    it "アクセストークンで本人のプロフィールを取る" do
      stub_request(:get, "https://discord.com/api/v10/users/@me")
        .with(headers: { "Authorization" => "Bearer user-token" })
        .to_return(status: 200, body: { id: "123", username: "taro", global_name: "Taro", avatar: "hash" }.to_json)

      expect(described_class.fetch_user("user-token")).to eq(
        "id" => "123", "username" => "taro", "global_name" => "Taro", "avatar" => "hash"
      )
    end

    it "失敗したら DiscordClient::Error を投げる" do
      stub_request(:get, "https://discord.com/api/v10/users/@me").to_return(status: 401, body: "{}")

      expect { described_class.fetch_user("user-token") }.to raise_error(DiscordClient::Error)
    end
  end

  describe ".add_guild_member" do
    it "Bot のトークンでサーバーに参加させる" do
      stub = stub_request(:put, "https://discord.com/api/v10/guilds/guild-id/members/123")
        .with(
          headers: { "Authorization" => "Bot bot-token", "Content-Type" => "application/json" },
          body: { access_token: "user-token" }.to_json
        )
        .to_return(status: 201, body: "{}")

      described_class.add_guild_member(user_id: "123", access_token: "user-token")

      expect(stub).to have_been_requested.once
    end

    it "参加済み（204）でも失敗しない" do
      stub_request(:put, "https://discord.com/api/v10/guilds/guild-id/members/123").to_return(status: 204, body: "")

      expect { described_class.add_guild_member(user_id: "123", access_token: "user-token") }.not_to raise_error
    end

    it "失敗したら DiscordClient::Error を投げる" do
      stub_request(:put, "https://discord.com/api/v10/guilds/guild-id/members/123").to_return(status: 403, body: "{}")

      expect {
        described_class.add_guild_member(user_id: "123", access_token: "user-token")
      }.to raise_error(DiscordClient::Error)
    end
  end
end
