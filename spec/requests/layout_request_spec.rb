require "rails_helper"

RSpec.describe "共通レイアウト", type: :request do
  it "日本語の文書として、本文へのスキップリンクと main を持つ" do
    get root_path

    html = Nokogiri::HTML(response.body)
    expect(html.at("html")["lang"]).to eq "ja"
    expect(html.at('a.skip-link[href="#main"]').text).to eq "本文へ移動"
    expect(html.at("main#main")).to be_present
  end

  it "ヘッダーのナビゲーションに名前を付け、ロゴはトップへのリンクで代替テキストを持つ" do
    get root_path

    html = Nokogiri::HTML(response.body)
    nav = html.at("header nav")
    expect(nav["aria-label"]).to eq "メイン"
    expect(html.at(%(header a[href="#{root_path}"] img))["alt"]).to eq "Beerkeeper トップへ"
  end

  it "ログイン中はアバターを飾りとしてマイページへのリンクに含める" do
    user = create(:user, name: "sakurai", discord_avatar: "hash1")
    log_in(user)

    get root_path

    html = Nokogiri::HTML(response.body)
    link = html.at(%(header a[href="#{user_path}"]))
    expect(link.at("img.avatar")["alt"]).to eq ""
    expect(link.text.strip).to eq "マイページ"
  end
end
