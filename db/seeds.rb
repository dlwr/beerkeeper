return if Rails.env.production?

users = [
  { name: "sakurai", discord_user_id: "seed-sakurai" },
  { name: "suzuki", discord_user_id: "seed-suzuki" },
  { name: "tanaka", discord_user_id: "seed-tanaka" }
].map do |attributes|
  User.find_or_create_by!(discord_user_id: attributes[:discord_user_id]) do |user|
    user.name = attributes[:name]
  end
end

organizer = users.first

Event.find_or_create_by!(name: "mitakarb") do |event|
  event.start_at = Time.current
  event.end_at = Time.current.tomorrow
  event.location = "mitaka"
  event.organizer = organizer
  event.max_size = 10
  event.budget = "5000"
  event.description = "Mitaka ruby"
end

events = (1..9).map do |number|
  start_at = (number - 5).weeks.from_now.change(hour: 19, min: 30)

  Event.find_or_create_by!(name: "mitaka.rb ##{number}") do |event|
    event.start_at = start_at
    event.end_at = start_at + 2.hours
    event.location = "三鷹市市民協働センター"
    event.organizer = users[number % users.size]
    event.max_size = 20
    event.budget = "500"
    event.description = "mitaka.rb の定例会 ##{number}"
  end
end

events.first(5).product(users.first(2)).each do |event, user|
  Participation.find_or_create_by!(event:, user:)
end
