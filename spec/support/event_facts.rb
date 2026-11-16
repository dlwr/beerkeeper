module EventFactHelpers
  def event_fact(label)
    html = Nokogiri::HTML(response.body)
    term = html.css("dl.event-facts dt").find { |dt| dt.text.strip == label }
    term&.next_element&.text.to_s.squish
  end
end

RSpec.configure do |config|
  config.include EventFactHelpers, type: :request
end
