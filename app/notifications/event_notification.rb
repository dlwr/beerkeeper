class EventNotification
  SCHEDULE_LABELS = { "start_at" => "開始日時", "end_at" => "終了日時", "location" => "開催場所" }.freeze
  LEADS = {
    "participation" => "参加登録を受け付けました。当日お会いできるのを楽しみにしています。",
    "waitlist" => "定員に達しているため、補欠として受け付けました。参加者にキャンセルが出ると申し込み順に繰り上がり、この DM でお知らせします。",
    "promotion" => "キャンセルが出たため、繰り上げで参加が確定しました。",
    "cancellation" => "ご参加登録いただいていたイベントは中止になりました。",
    "schedule_change" => "開催日時・場所が変更されました。"
  }.freeze

  def initialize(kind, user:, event:, changes: {})
    @kind = kind.to_s
    @user = user
    @event = event
    @changes = changes
  end

  def content
    [
      "#{@user.name} さん",
      "【#{@event.name}】#{LEADS.fetch(@kind)}",
      "",
      *change_lines,
      "日時：#{format_value(@event.start_at)}",
      "場所：#{format_value(@event.location)}",
      *reason_lines,
      "",
      Rails.application.routes.url_helpers.event_url(@event, **Rails.application.config.action_mailer.default_url_options)
    ].join("\n")
  end

  private

  def change_lines
    return [] unless @kind == "schedule_change"

    lines = @changes.map { |attribute, (before, after)| "#{SCHEDULE_LABELS.fetch(attribute)}：#{format_value(before)} → #{format_value(after)}" }
    [ *lines, "" ]
  end

  def reason_lines
    reason = @event.cancellation&.reason if @kind == "cancellation"
    reason.present? ? [ "中止理由：#{reason}" ] : []
  end

  def format_value(value)
    value.respond_to?(:strftime) ? I18n.l(value) : value.presence || "未定"
  end
end
