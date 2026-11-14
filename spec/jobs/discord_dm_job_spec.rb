require "rails_helper"

RSpec.describe DiscordDmJob, :discord do
  include ActiveJob::TestHelper

  let(:user) { User.sign_in_with_discord("id" => "123", "username" => "taro", "avatar" => nil) }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  before { allow(Rails).to receive(:cache).and_return(cache) }

  it "本人に DM を送る" do
    allow(DiscordClient).to receive(:send_dm)

    described_class.perform_now(user, "こんにちは")

    expect(DiscordClient).to have_received(:send_dm).with(user_id: "123", content: "こんにちは")
  end

  it "Discord に紐づいていないユーザーには送らない" do
    allow(DiscordClient).to receive(:send_dm)

    described_class.perform_now(create(:user), "こんにちは")

    expect(DiscordClient).not_to have_received(:send_dm)
  end

  it "積んだあとにユーザーが消えていれば、送らずに捨てる" do
    allow(DiscordClient).to receive(:send_dm)
    described_class.perform_later(user, "こんにちは")
    user.destroy!

    expect { perform_enqueued_jobs }.not_to raise_error
    expect(DiscordClient).not_to have_received(:send_dm)
  end

  it "429 なら retry_after だけ待って再試行する" do
    allow(DiscordClient).to receive(:send_dm).and_raise(DiscordClient::RateLimited.new("rate limited", retry_after: 2.5))

    freeze_time do
      described_class.perform_now(user, "こんにちは")

      expect(described_class).to have_been_enqueued.with(user, "こんにちは").at(2.5.seconds.from_now)
    end
  end

  it "歓迎以外の送信の失敗はログに残すだけにする" do
    allow(DiscordClient).to receive(:send_dm).and_raise(DiscordClient::Error.new("forbidden", code: 50007))
    allow(Rails.logger).to receive(:warn)

    expect { described_class.perform_now(user, "こんにちは") }.not_to raise_error

    expect(Rails.logger).to have_received(:warn).with(/Discord DM/)
    expect(DiscordDmJob.welcome_failed?(user)).to be false
  end

  it "歓迎の DM が失敗したら、失敗したことを覚えておく" do
    allow(DiscordClient).to receive(:send_dm).and_raise(DiscordClient::Error.new("forbidden", code: 50007))

    described_class.perform_now(user, "ようこそ", welcome: true)

    expect(DiscordDmJob.welcome_failed?(user)).to be true
  end
end
