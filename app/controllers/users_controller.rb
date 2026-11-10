class UsersController < ApplicationController
  before_action :require_login
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  # GET /users
  def show
    @participations = @user.participations.joins(:event).merge(Event.upcoming).includes(event: :cancellation)
    @attended_participations = @user.participations.confirmed.joins(:event).merge(Event.not_cancelled.past).includes(:event)
    @organizing_events = @user.organizing_events.upcoming.includes(:cancellation)
    @organized_events = @user.organizing_events.past.includes(:cancellation)
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
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
