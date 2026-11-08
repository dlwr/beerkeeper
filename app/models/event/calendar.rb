class Event::Calendar
  LINE_LIMIT = 75

  def initialize(event, url:)
    @event = event
    @url = url
  end

  def to_ics
    lines.map { |line| fold(line) }.join("\r\n") + "\r\n"
  end

  private

  attr_reader :event, :url

  def lines
    [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//beerkeeper//JA",
      "CALSCALE:GREGORIAN",
      "BEGIN:VEVENT",
      "UID:event-#{event.id}@#{URI.parse(url).host}",
      "DTSTAMP:#{format_time(stamp)}",
      "DTSTART:#{format_time(event.start_at)}",
      "DTEND:#{format_time(event.end_at)}",
      "SUMMARY:#{escape(event.name)}",
      *location_line,
      "DESCRIPTION:#{escape(description)}",
      "URL:#{url}",
      "STATUS:#{event.cancelled? ? 'CANCELLED' : 'CONFIRMED'}",
      "END:VEVENT",
      "END:VCALENDAR"
    ]
  end

  def location_line
    location = event.location
    location.present? ? [ "LOCATION:#{escape(location.to_s)}" ] : []
  end

  def stamp
    [ event.updated_at, event.cancelled_at ].compact.max
  end

  def description
    [ event.description.presence, url ].compact.join("\n\n")
  end

  def format_time(time)
    time&.utc&.strftime("%Y%m%dT%H%M%SZ")
  end

  def escape(text)
    text.to_s.gsub(/[\\,;]/) { |char| "\\#{char}" }.gsub(/\r\n|\r|\n/, "\\n")
  end

  def fold(line)
    chunks = [ +"" ]
    line.each_char do |char|
      limit = chunks.size == 1 ? LINE_LIMIT : LINE_LIMIT - 1
      chunks << +"" if chunks.last.bytesize + char.bytesize > limit
      chunks.last << char
    end
    chunks.join("\r\n ")
  end
end
