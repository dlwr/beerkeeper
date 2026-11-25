class ParticipationsController < ApplicationController
  before_action :require_login

  def create
    event = Event.not_cancelled.find(params[:event_id])

    participation = event.receive(current_user)
    if participation&.waitlisted?
      flash[:success] = "定員に達しているため補欠として登録しました（補欠の#{event.waitlist_position(current_user)}番目）。繰り上がったら Discord の DM でお知らせします"
    elsif participation
      flash[:success] = "参加登録しました。Discord の DM でもお知らせします"
    else
      flash[:alert] = receive_failure_message(event)
      return redirect_to event_path(event)
    end
    redirect_back fallback_location: event_path(event)
  end

  def destroy
    event = Event.not_cancelled.find(params[:event_id])
    participation = current_user&.participations&.find_by(id: params[:id], event:)

    if !event.ended? && participation&.destroy
      flash[:success] = "参加をキャンセルしました"
    else
      flash[:alert] = "参加をキャンセルできませんでした"
    end
    redirect_to event_path(event)
  end

  private

  def receive_failure_message(event)
    existing = current_user.participations.find_by(event:)
    if existing&.waitlisted?
      "すでに補欠として登録しています（補欠の#{event.waitlist_position(current_user)}番目）"
    elsif existing
      "すでに参加登録しています"
    elsif event.ended?
      "終了したイベントには参加できません"
    elsif event.cancelled?
      "このイベントは中止されました"
    else
      "イベントに参加できませんでした"
    end
  end
end
