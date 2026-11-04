class EventsController < ApplicationController
  before_action :require_login, except: %i[index show]
  before_action :set_event, only: %i[show]
  before_action :set_editable_event, only: %i[edit update destroy]
  before_action :authorize_organizer, only: %i[edit update destroy]

  # GET /events
  def index
    @upcoming_events = Event.not_cancelled.upcoming
    @past_events = Event.not_cancelled.past
  end

  # GET /events/1
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  def create
    @event = Event.new(event_params)
    @event.organizer_id = current_user.id

    if @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      flash.now[:alert] = @event.errors.full_messages.join("\u3001")
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /events/1
  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      flash.now[:alert] = @event.errors.full_messages.join("\u3001")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /events/1
  def destroy
    if @event.destroy
      redirect_to events_url, notice: "Event was successfully destroyed."
    else
      redirect_to @event, alert: "Event could not be destroyed."
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
      redirect_to root_url, notice: "\u30AA\u30FC\u30AC\u30CA\u30A4\u30B6\u30FC\u3067\u306F\u306A\u3044\u305F\u3081\u7DE8\u96C6\u3067\u304D\u307E\u305B\u3093\u3002" unless @event.organizer?(current_user)
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

      if permitted[:end_at_date].present? && permitted[:end_at_time].present?
        permitted[:end_at] = parse_datetime(permitted[:end_at_date], permitted[:end_at_time])
      end
      permitted
    end

    def parse_datetime(date, time)
      return nil if date.blank? || time.blank?

      Time.zone.strptime("#{date} #{time}", "%Y-%m-%d %H:%M")
    rescue ArgumentError
      nil
    end
end
