class UsersController < ApplicationController
  PAST_EVENTS_ON_SHOW = 5

  before_action :require_login
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  # GET /users
  def show
    @participations = @user.participations.joins(:event).merge(Event.upcoming).includes(event: :cancellation)
    attended = @user.participations.confirmed.joins(:event).merge(Event.not_cancelled.past)
    @attended_participations = attended.includes(:event).limit(PAST_EVENTS_ON_SHOW)
    @more_attended_count = [ attended.count - PAST_EVENTS_ON_SHOW, 0 ].max
    @organizing_events = @user.organizing_events.upcoming.includes(:cancellation)
    organized = @user.organizing_events.past
    @organized_events = organized.includes(:cancellation).limit(PAST_EVENTS_ON_SHOW)
    @more_organized_count = [ organized.count - PAST_EVENTS_ON_SHOW, 0 ].max
  end

  # GET /users/edit
  def edit
  end

  # PATCH/PUT /users
  def update
    if @user.update(user_params)
      redirect_to user_path, notice: "ユーザー情報を更新しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /users/1
  def destroy
    if @user.destroy
      redirect_to root_url, notice: "ユーザーを削除しました"
    else
      redirect_to user_url, alert: "ユーザーを削除できませんでした"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = current_user
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit(:name)
    end
end
