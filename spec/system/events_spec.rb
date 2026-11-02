require "rails_helper"

RSpec.describe "events", type: :system, js: true do
  it "enables me to create widgets" do
    visit "/events" # /booksへHTTPメソッドGETでアクセス
    expect(page).to have_text("イベント一覧") # 表示されたページに Books という文字があることを確認
  end

  it "enables me to show an event" do
    user1 = create(:user, name: "User 1")
    user2 = create(:user, name: "User 2")
    event = create(:event)
    create(:participation, user: user1, event:)
    create(:participation, user: user2, event:)

    visit "/events/#{event.id}"
    expect(page).to have_text(event.name)
    expect(page).to have_text("参加者リスト")
    expect(page).to have_text(user1.name)
    expect(page).to have_text(user2.name)
  end

  it "lets the organizer cancel an event with a reason" do
    organizer = create(:user)
    event = create(:event, organizer:)
    allow_any_instance_of(ApplicationController).to receive(:current_user) { organizer }

    visit "/events/#{event.id}"
    fill_in "中止理由", with: "台風のため"
    accept_confirm { click_on "イベント中止" }
    expect(page).to have_text("イベントを中止しました")

    visit "/events/#{event.id}"
    expect(page).to have_text("このイベントは中止されました")
    expect(page).to have_text("台風のため")
  end
end
