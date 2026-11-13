require "rails_helper"

RSpec.describe "Discord でのログイン", type: :request do
  let(:callback_url) { "http://www.example.com/auth/discord/callback" }

  def start_login
    post discord_login_path
    Rack::Utils.parse_query(URI.parse(response.location).query).fetch("state")
  end

  def stub_discord(profile: { id: "123", username: "taro", global_name: "Taro", avatar: "hash1" }, join_status: 201)
    stub_request(:post, "https://discord.com/api/v10/oauth2/token")
      .to_return(status: 200, body: { access_token: "user-token" }.to_json)
    stub_request(:get, "https://discord.com/api/v10/users/@me")
      .to_return(status: 200, body: profile.to_json)
    stub_request(:put, "https://discord.com/api/v10/guilds/guild-id/members/#{profile[:id]}")
      .to_return(status: join_status, body: "{}")
  end

  context "Discord のシークレットがある環境", :discord do
    it "ログイン画面に Discord でログインのボタンが出る" do
      get login_path

      expect(response.body).to include("Discord でログイン")
    end

    it "POST /auth/discord で Discord の認可画面にリダイレクトする" do
      post discord_login_path

      expect(response).to have_http_status(:see_other).or have_http_status(:found)
      expect(response.location).to start_with("https://discord.com/oauth2/authorize?")
      expect(Rack::Utils.parse_query(URI.parse(response.location).query)).to include("redirect_uri" => callback_url)
    end

    it "未登録の Discord アカウントならユーザーを作ってログインする" do
      stub_discord
      state = start_login

      expect {
        get discord_callback_path, params: { code: "the-code", state: }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(events_path)
      follow_redirect!
      expect(response.body).to include("ログインに成功しました", "ログアウト", "https://cdn.discordapp.com/avatars/123/hash1.png?size=64")
      expect(User.last).to have_attributes(discord_user_id: "123", name: "Taro")
    end

    it "登録済みの Discord アカウントなら同じユーザーでログインし、名前は変えない" do
      user = User.sign_in_with_discord("id" => "123", "username" => "taro", "global_name" => "Taro", "avatar" => "hash1")
      user.update!(name: "たろう")
      stub_discord(profile: { id: "123", username: "taro", global_name: "Other", avatar: "hash2" })
      state = start_login

      expect {
        get discord_callback_path, params: { code: "the-code", state: }
      }.not_to change(User, :count)

      expect(user.reload).to have_attributes(name: "たろう", discord_avatar: "hash2")
      follow_redirect!
      expect(response.body).to include("ログアウト")
    end

    it "ログインのたびにサーバー参加の API を呼ぶ" do
      stub_discord
      2.times do
        state = start_login
        get discord_callback_path, params: { code: "the-code", state: }
        delete session_path(User.last)
      end

      expect(a_request(:put, "https://discord.com/api/v10/guilds/guild-id/members/123")
        .with(headers: { "Authorization" => "Bot bot-token" }, body: { access_token: "user-token" }.to_json)).to have_been_made.twice
    end

    it "サーバー参加の API が失敗してもログインでき、ログに残る" do
      stub_discord(join_status: 403)
      allow(Rails.logger).to receive(:warn)
      state = start_login

      get discord_callback_path, params: { code: "the-code", state: }

      expect(response).to redirect_to(events_path)
      expect(Rails.logger).to have_received(:warn).with(/Discord/)
    end

    it "同じ state は2回使えない" do
      stub_discord
      state = start_login
      get discord_callback_path, params: { code: "the-code", state: }

      get discord_callback_path, params: { code: "the-code", state: }

      expect(response).to redirect_to(login_path)
    end

    it "OAuth を拒否したらログイン画面に戻り、理由を出す" do
      state = start_login

      get discord_callback_path, params: { error: "access_denied", state: }

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Discord での認可がキャンセルされました")
    end

    it "state が合わなければログインさせない" do
      stub_discord
      start_login

      expect {
        get discord_callback_path, params: { code: "the-code", state: "wrong" }
      }.not_to change(User, :count)

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Discord でのログインに失敗しました")
    end

    it "トークンの取得に失敗したらログイン画面に戻り、理由を出す" do
      stub_request(:post, "https://discord.com/api/v10/oauth2/token").to_return(status: 400, body: "{}")
      state = start_login

      get discord_callback_path, params: { code: "bad", state: }

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Discord でのログインに失敗しました")
    end
  end

  context "Discord のシークレットが無い環境", :without_discord do
    it "ログイン画面にボタンを出さない" do
      get login_path

      expect(response.body).not_to include("Discord でログイン")
    end

    it "POST /auth/discord は 404" do
      post discord_login_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
