require "rails_helper"

RSpec.describe EventNotification do
  let(:user) { create(:user, name: "たろう") }
  let(:event) { create(:event, name: "mitaka.rb #1", location: "三鷹", start_at: Time.zone.local(2099, 1, 15, 19, 0), end_at: Time.zone.local(2099, 1, 15, 21, 0)) }
  let(:url) { "http://example.com/events/#{event.id}" }

  def content(kind, changes = {})
    described_class.new(kind, user:, event:, changes:).content
  end

  it "参加登録の通知にイベント名・日時・場所・URL を入れる" do
    expect(content("participation")).to include("【mitaka.rb #1】参加登録を受け付けました", "日時：2099年1月15日(木) 19:00〜21:00", "三鷹", url)
  end

  it "補欠登録の通知" do
    expect(content("waitlist")).to include("補欠として受け付けました", "三鷹", url)
  end

  it "繰り上げの通知" do
    expect(content("promotion")).to include("繰り上げで参加が確定しました", "三鷹", url)
  end

  it "中止の通知に理由を入れる" do
    event.cancel("台風")

    expect(content("cancellation")).to include("中止になりました", "中止理由：台風", url)
  end

  it "日時・場所の変更の通知に変わった項目の前後を入れる" do
    text = content("schedule_change", { "location" => [ "三鷹", "吉祥寺" ], "start_at" => [ Time.zone.local(2099, 1, 15, 19, 0), Time.zone.local(2099, 1, 22, 19, 0) ] })

    expect(text).to include("開催日時・場所が変更されました", "開催場所：三鷹 → 吉祥寺", "開始日時：2099年01月15日(木) 19時00分 → 2099年01月22日(木) 19時00分", url)
  end

  %w[participation waitlist promotion cancellation schedule_change].each do |kind|
    it "#{kind} の通知の日時に終了時刻を入れる" do
      event.cancel if kind == "cancellation"

      expect(content(kind)).to include("日時：2099年1月15日(木) 19:00〜21:00")
    end
  end

  it "日をまたぐイベントは終了の日付も入れる" do
    event.update!(end_at: Time.zone.local(2099, 1, 16, 1, 0))

    expect(content("participation")).to include("日時：2099年1月15日(木) 19:00〜1月16日 01:00")
  end

  it "場所が空なら未定と書く" do
    event.update_column(:location, "")

    expect(content("participation")).to include("場所：未定")
  end
end
