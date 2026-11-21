module EventsHelper
  URL_PATTERN = %r{https?://[!#-;=?-~]+}
  URL_TRAILING_PUNCTUATION = /[.,!?;:')\]]+\z/

  def participant_count_label(event)
    count = event.confirmed_participations.size
    limit = event.max_size
    limit.nil? ? "#{count}人（定員なし）" : "#{count}人 / #{limit}人"
  end

  def seats_full?(event)
    limit = event.max_size
    !limit.nil? && !event.ended? && event.confirmed_participations.size >= limit
  end

  def event_date_label(event)
    l(event.start_at, format: "%Y年%-m月%-d日(%a)")
  end

  def event_time_range(event)
    start_at = event.start_at
    end_at = event.end_at
    end_format = start_at.to_date == end_at.to_date ? "%H:%M" : "%-m月%-d日 %H:%M"
    "#{l(start_at, format: '%H:%M')}〜#{l(end_at, format: end_format)}"
  end

  def event_timing_label(event)
    return if event.ended?

    now = Time.current
    if event.start_at <= now
      "開催中"
    elsif event.start_at.to_date == now.to_date
      "今日"
    end
  end

  def seats_status(event)
    return "終了" if event.ended?

    limit = event.max_size
    return "定員なし" if limit.nil?

    left = limit - event.confirmed_participations.size
    left.positive? ? "あと#{left}人" : "満席・補欠受付中"
  end

  def field_error_id(record, attribute)
    "#{record.model_name.param_key}_#{attribute}_error"
  end

  def field_error_attributes(record, attribute)
    return {} if record.errors[attribute].empty?

    { aria: { invalid: true, describedby: field_error_id(record, attribute) } }
  end

  def field_error(record, attribute)
    return if record.errors[attribute].empty?

    tag.p(record.errors.full_messages_for(attribute).join("\u3001"), id: field_error_id(record, attribute), class: "field-error")
  end

  def budget_label(event)
    budget = event.budget.to_s.strip
    return "未定" if budget.empty?

    budget.match?(/\A\d+\z/) ? "#{budget}円" : budget
  end

  def text_with_links(text)
    parts = []
    rest = text.to_s
    while (match = URL_PATTERN.match(rest))
      url = match[0].sub(URL_TRAILING_PUNCTUATION, "")
      parts << match.pre_match << link_to(url, url, target: "_blank", rel: "noopener noreferrer nofollow ugc", class: "text-link")
      rest = rest[(match.begin(0) + url.length)..].to_s
    end
    parts << rest
    safe_join(parts)
  end

  def format_with_links(text, html_options = {})
    simple_format(text_with_links(text), html_options, sanitize: false)
  end

  def event_share_description(event)
    [
      ("中止" if event.cancelled?),
      event_date_label(event),
      event_time_range(event),
      event.location.presence
    ].compact.join(" ")
  end
end
