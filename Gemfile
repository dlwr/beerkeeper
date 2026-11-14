source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

gem "rails", "~> 8.1.4"

gem "bcrypt", "~> 3.1.22"
gem "bootsnap", require: false
gem "bootstrap", "~> 5.3.8"
gem "dartsass-rails", "~> 0.5.1"
gem "falcon"
gem "importmap-rails"
gem "jbuilder"
gem "propshaft"
gem "puma", "~> 8.0"
gem "rails-i18n"
gem "redis", "~> 6.0"
gem "solid_queue", "~> 1.7"
gem "sqlite3", "~> 2.9"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "view_component", "~> 4.15"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  gem "letter_opener", "~> 1.10"
  gem "rbs", require: false
  gem "rbs_rails", require: false
  gem "steep", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "selenium-webdriver"
  gem "webmock"
end

gem "rubocop-rails-omakase", "~> 1.1", group: :development, require: false
