class Events::CancellationsController < ApplicationController
  def create
    @event = Event.not_cancelled.find(params[:event_id])
    @event.cancel(params.dig(:cancellation, :reason))

    redirect_to root_path, notice: "\u30A4\u30D9\u30F3\u30C8\u3092\u4E2D\u6B62\u3057\u307E\u3057\u305F"
  end
end
