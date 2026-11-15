FactoryBot.define do
  factory :user do
    name { "MyString" }
    sequence(:discord_user_id) { |n| (100_000 + n).to_s }
  end
end
