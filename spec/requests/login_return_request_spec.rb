require "rails_helper"

RSpec.describe "ログイン画面とログイン後の戻り先", type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  describe "GET /login", :discord do
    it "押すと何が起きるかを書き、主な操作は Discord でログインの1つだけにする" do
      get login_path

      html = Nokogiri::HTML(response.body)
      main = html.at("main")
      expect(main.text).to include("Discord のアカウント", "Discord サーバーに参加", "DM で届きます")
      expect(main.css(".btn-primary").map { |b| b.text.squish }).to eq [ "Discord でログイン" ]
      expect(html.at(%(header a[href^="#{login_path}"]))).to be_nil
    end
  end

  it "イベント詳細から「ログインして参加する」でログインすると、そのイベント詳細に戻る" do
    get event_path(event)
    href = Nokogiri::HTML(response.body).css("main a").find { |a| a.text.strip == "Discord でログインして参加する" }["href"]

    get href
    log_in(user)

    expect(response).to redirect_to(event_path(event))
  end

  it "ログインが要る画面から来たら、ログイン後にその画面へ戻る" do
    get new_event_path
    expect(response).to redirect_to(login_path)

    log_in(user)

    expect(response).to redirect_to(new_event_path)
  end

  it "ヘッダーのログインは今の画面を戻り先にする" do
    get event_path(event)

    link = Nokogiri::HTML(response.body).at("header a.btn")
    expect(link["href"]).to eq login_path(return_to: event_path(event))
  end

  it "戻り先が無ければイベント一覧へ行く" do
    log_in(user)

    expect(response).to redirect_to(events_path)
  end

  [ "//evil.example.com", "https://evil.example.com/", "/\\evil.example.com", "javascript:alert(1)" ].each do |target|
    it "ほかのサイトへの戻り先（#{target}）は使わない" do
      get login_path(return_to: target)
      log_in(user)

      expect(response).to redirect_to(events_path)
    end
  end

  it "長すぎる戻り先は覚えず、ログイン画面を開ける" do
    get login_path(return_to: "/#{'a' * 5000}")
    expect(response).to have_http_status(:ok)

    log_in(user)

    expect(response).to redirect_to(events_path)
  end
end
