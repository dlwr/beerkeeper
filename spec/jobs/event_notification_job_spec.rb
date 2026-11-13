require "rails_helper"

RSpec.describe EventNotificationJob do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  it "通知の文面を作り、本人に DM で送る" do
    allow(DiscordDmJob).to receive(:perform_now)

    described_class.perform_now("participation", user, event)

    expect(DiscordDmJob).to have_received(:perform_now).with(user, a_string_including("参加登録を受け付けました", event.name))
  end

  it "変更の前後を渡せる" do
    allow(DiscordDmJob).to receive(:perform_now)

    described_class.perform_now("schedule_change", user, event, { "location" => [ "三鷹", "吉祥寺" ] })

    expect(DiscordDmJob).to have_received(:perform_now).with(user, a_string_including("三鷹 → 吉祥寺"))
  end
end
