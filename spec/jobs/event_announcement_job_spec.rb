require "rails_helper"

RSpec.describe EventAnnouncementJob, :discord do
  let(:event) { create(:event, name: "mitaka.rb #1", location: "三鷹", max_size: 20, start_at: Time.zone.local(2099, 1, 15, 19, 0), end_at: Time.zone.local(2099, 1, 15, 21, 0)) }

  around { |example| with_env("DISCORD_EVENTS_CHANNEL_ID" => "events-channel") { example.run } }

  before { allow(DiscordClient).to receive(:post_message) }

  it "新しいイベントのイベント名・日時・場所・定員・URL を #events に投稿する" do
    described_class.perform_now("created", event)

    expect(DiscordClient).to have_received(:post_message).with(
      channel_id: "events-channel",
      content: a_string_including("mitaka.rb #1", "2099年01月15日(木) 19時00分", "三鷹", "定員：20 人", "http://example.com/events/#{event.id}")
    ).once
  end

  it "定員が無ければ定員なしと書く" do
    event.update_column(:max_size, nil)

    described_class.perform_now("created", event)

    expect(DiscordClient).to have_received(:post_message).with(channel_id: "events-channel", content: a_string_including("定員：なし"))
  end

  it "中止を理由つきで投稿する" do
    event.cancel("台風")

    described_class.perform_now("cancelled", event)

    expect(DiscordClient).to have_received(:post_message).with(channel_id: "events-channel", content: a_string_including("中止", "mitaka.rb #1", "中止理由：台風"))
  end

  it "DISCORD_EVENTS_CHANNEL_ID が無ければ何もしない" do
    with_env("DISCORD_EVENTS_CHANNEL_ID" => nil) { described_class.perform_now("created", event) }

    expect(DiscordClient).not_to have_received(:post_message)
  end

  it "投稿に失敗してもログに残すだけにする" do
    allow(DiscordClient).to receive(:post_message).and_raise(DiscordClient::Error.new("forbidden", code: 50001))
    allow(Rails.logger).to receive(:warn)

    expect { described_class.perform_now("created", event) }.not_to raise_error
    expect(Rails.logger).to have_received(:warn).with(/Discord announcement/)
  end

  it "429 なら retry_after だけ待って再試行する" do
    allow(DiscordClient).to receive(:post_message).and_raise(DiscordClient::RateLimited.new("rate limited", retry_after: 3))

    freeze_time do
      described_class.perform_now("created", event)

      expect(described_class).to have_been_enqueued.with("created", event).at(3.seconds.from_now)
    end
  end
end
