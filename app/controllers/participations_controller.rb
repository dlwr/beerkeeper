class ParticipationsController < ApplicationController
  def create
    event = Event.not_cancelled.find(params[:event_id])

    participation = event.receive(current_user)
    if participation&.waitlisted?
      flash[:success] = "定員に達しているため補欠として登録しました（補欠の#{event.waitlist_position(current_user)}番目）"
    elsif participation
      flash[:success] = "イベント参加登録しました"
    else
      flash[:alert] = "イベントに参加できませんでした"
    end
    redirect_back fallback_location: event_path(event)
  end

  def destroy
    event = Event.not_cancelled.find(params[:event_id])
    participation = current_user&.participations&.find_by(id: params[:id], event:)

    if participation&.destroy
      flash[:success] = "イベント参加をキャンセルしました"
    else
      flash[:alert] = "イベント参加をキャンセルできませんでした"
    end
    redirect_to event_path(event)
  end
end
