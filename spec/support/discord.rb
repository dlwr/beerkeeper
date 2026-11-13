module DiscordHelpers
  DISCORD_ENV = {
    "DISCORD_CLIENT_ID" => "client-id",
    "DISCORD_CLIENT_SECRET" => "client-secret",
    "DISCORD_BOT_TOKEN" => "bot-token",
    "DISCORD_GUILD_ID" => "guild-id"
  }.freeze

  def with_env(values, &block)
    original = values.keys.index_with { |key| ENV[key] }
    ENV.update(values)
    block.call
  ensure
    original&.each { |key, value| ENV[key] = value }
  end
end

RSpec.configure do |config|
  config.include DiscordHelpers
  config.around(:each, :discord) do |example|
    with_env(DiscordHelpers::DISCORD_ENV) { example.run }
  end
  config.around(:each, :without_discord) do |example|
    with_env(DiscordHelpers::DISCORD_ENV.transform_values { nil }) { example.run }
  end
end
