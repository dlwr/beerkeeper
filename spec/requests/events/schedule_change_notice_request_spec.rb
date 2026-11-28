require "rails_helper"

RSpec.describe "日時・場所の変更を知らせる案内", type: :request do
  let(:organizer) { create(:user) }
  let(:event) { create(:event, organizer:, max_size: 1, location: "三鷹") }

  before { log_in(organizer) }

  def notice_text
    Nokogiri::HTML(response.body).at("main .schedule-change-notice")&.text&.squish
  end

  context "参加者と補欠がいるとき" do
    before do
      create(:participation, event:, user: create(:user))
      create(:participation, event:, user: create(:user), waitlisted: true)
    end

    it "編集画面に知らせる人数を出す" do
      get edit_event_path(event)

      expect(notice_text).to eq "日時・開催場所を変えると、参加者と補欠の2人に DM で知らせます"
    end

    it "場所を変えて保存するとフラッシュで人数を伝える" do
      patch event_path(event), params: { event: { location: "吉祥寺" } }

      expect(flash[:notice]).to eq "イベントを更新しました。変更を参加者と補欠の2人に DM で知らせます"
    end

    it "日時を変えて保存するとフラッシュで人数を伝える" do
      patch event_path(event), params: { event: { start_at_date: "2099-03-14", start_at_time: "18:00",
                                                  end_at_date: "2099-03-14", end_at_time: "21:00" } }

      expect(flash[:notice]).to eq "イベントを更新しました。変更を参加者と補欠の2人に DM で知らせます"
    end

    it "日時と場所以外だけを変えたときは知らせると言わない" do
      patch event_path(event), params: { event: { name: "名前を変えた会" } }

      expect(flash[:notice]).to eq "イベントを更新しました"
    end
  end

  context "参加者も補欠もいないとき" do
    it "編集画面に案内を出さない" do
      get edit_event_path(event)

      expect(notice_text).to be_nil
    end

    it "場所を変えても知らせると言わない" do
      patch event_path(event), params: { event: { location: "吉祥寺" } }

      expect(flash[:notice]).to eq "イベントを更新しました"
    end
  end

  it "作成画面には案内を出さない" do
    get new_event_path

    expect(notice_text).to be_nil
  end
end
