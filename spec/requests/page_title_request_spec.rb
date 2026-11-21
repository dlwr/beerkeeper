require "rails_helper"

RSpec.describe "画面のタイトル", type: :request do
  def page_title
    Nokogiri::HTML(response.body).at("title").text
  end

  let(:organizer) { create(:user) }
  let(:event) { create(:event, name: "三鷹 Ruby <会>", organizer:) }

  it "一覧と過去のイベント" do
    get root_path
    expect(page_title).to eq "イベント一覧｜Beerkeeper"

    get past_events_path
    expect(page_title).to eq "過去のイベント｜Beerkeeper"
  end

  it "イベント詳細はイベント名を入れる" do
    get event_path(event)
    expect(page_title).to eq "三鷹 Ruby <会>｜Beerkeeper"
  end

  it "ログイン" do
    get login_path
    expect(page_title).to eq "ログイン｜Beerkeeper"
  end

  context "ログイン中" do
    before { log_in(organizer) }

    it "作成と編集" do
      get new_event_path
      expect(page_title).to eq "イベントを作成｜Beerkeeper"

      get edit_event_path(event)
      expect(page_title).to eq "三鷹 Ruby <会>を編集｜Beerkeeper"
    end

    it "編集で名前を空にして送り直しても、保存済みの名前を出す" do
      patch event_path(event), params: { event: { name: "" } }
      expect(page_title).to eq "三鷹 Ruby <会>を編集｜Beerkeeper"
    end

    it "マイページと名前の編集" do
      get user_path
      expect(page_title).to eq "マイページ｜Beerkeeper"

      get edit_user_path
      expect(page_title).to eq "名前の編集｜Beerkeeper"
    end
  end
end
