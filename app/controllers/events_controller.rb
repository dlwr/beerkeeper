class EventsController < ApplicationController
  PAST_EVENTS_ON_INDEX = 5
  PAST_EVENTS_PER_PAGE = 20

  before_action :require_login, except: %i[index show past]
  before_action :set_event, only: %i[show]
  before_action :set_editable_event, only: %i[edit update destroy]
  before_action :authorize_organizer, only: %i[edit update destroy]

  # GET /events
  def index
    @upcoming_events = Event.not_cancelled.upcoming.includes(:confirmed_participations)
    past_events = Event.not_cancelled.past.includes(:confirmed_participations).limit(PAST_EVENTS_ON_INDEX + 1).to_a
    @more_past_events = past_events.size > PAST_EVENTS_ON_INDEX
    @past_events = past_events.first(PAST_EVENTS_ON_INDEX)
    @participation_states = current_user ? current_user.participations.where(event: @upcoming_events).pluck(:event_id, :waitlisted).to_h : {}
  end

  # GET /events/past
  def past
    @page = Integer(params[:page].to_s, 10, exception: false).to_i.clamp(1, 10_000)
    events = Event.not_cancelled.past.includes(:confirmed_participations)
                  .offset((@page - 1) * PAST_EVENTS_PER_PAGE).limit(PAST_EVENTS_PER_PAGE + 1).to_a
    @older_page = @page + 1 if events.size > PAST_EVENTS_PER_PAGE
    @past_events = events.first(PAST_EVENTS_PER_PAGE)
  end

  # GET /events/1
  def show
    respond_to do |format|
      format.html
      format.ics do
        send_data Event::Calendar.new(@event, url: event_url(@event)).to_ics,
                  type: :ics, filename: "event-#{@event.id}.ics"
      end
    end
  end

  # GET /events/new
  def new
    source = current_user.organizing_events.find_by(id: params[:source_id]) if params[:source_id].present?
    @event = source ? source.copy : Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  def create
    @event = Event.new(event_params)
    @event.organizer_id = current_user.id

    if @event.save
      redirect_to @event, notice: "イベントを作成しました"
    else
      flash.now[:alert] = "入力内容を確認してください（#{@event.errors.count}件）"
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /events/1
  def update
    if @event.update(event_params)
      redirect_to @event, notice: update_notice
    else
      flash.now[:alert] = "入力内容を確認してください（#{@event.errors.count}件）"
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /events/1
  def destroy
    if @event.destroy
      redirect_to events_url, notice: "イベントを削除しました"
    else
      redirect_to @event, alert: "イベントを削除できませんでした"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    def set_editable_event
      @event = Event.not_cancelled.find(params[:id])
    end

    def authorize_organizer
      redirect_to root_url, notice: "\u30AA\u30FC\u30AC\u30CA\u30A4\u30B6\u30FC\u3067\u306F\u306A\u3044\u305F\u3081\u7DE8\u96C6\u3067\u304D\u307E\u305B\u3093\u3002" unless @event.organized_by?(current_user)
    end

    # Only allow a trusted parameter "white list" through.
    def event_params
      permitted = params.fetch(:event, {}).permit(
        :start_at,
        :end_at,
        :start_at_date,
        :start_at_time,
        :end_at_date,
        :end_at_time,
        :location,
        :name,
        :max_size,
        :budget,
        :description,
        :participant_notice
      )

      if permitted[:start_at_date].present? && permitted[:start_at_time].present?
        permitted[:start_at] = parse_datetime(permitted[:start_at_date], permitted[:start_at_time])
      end

      if permitted[:end_at_time].present?
        end_date = permitted[:end_at_date].presence || permitted[:start_at_date]
        permitted[:end_at] = parse_datetime(end_date, permitted[:end_at_time]) if end_date.present?
      end
      permitted
    end

    def update_notice
      notified = @event.participations.count
      return "イベントを更新しました" unless notified.positive? && @event.saved_changes.keys.intersect?(Event::SCHEDULE_ATTRIBUTES)

      "イベントを更新しました。変更を参加者と補欠の#{notified}人に DM で知らせます"
    end

    def parse_datetime(date, time)
      return nil if date.blank? || time.blank?

      Time.zone.strptime("#{date} #{time}", "%Y-%m-%d %H:%M")
    rescue ArgumentError
      nil
    end
end
