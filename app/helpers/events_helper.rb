module EventsHelper
  def participant_count_label(event)
    count = event.participants.size
    limit = event.max_size
    limit.nil? ? "#{count}人（定員なし）" : "#{count}人 / #{limit}人"
  end

  def budget_label(event)
    budget = event.budget.to_s.strip
    return "未定" if budget.empty?

    budget.match?(/\A\d+\z/) ? "#{budget}円" : budget
  end
end
