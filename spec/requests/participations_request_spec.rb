require 'rails_helper'

RSpec.describe "Participations", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:event) { create(:event, max_size: 1) }

  def log_in(user)
    post sessions_path, params: { email: user.email, password: 'password' }
  end

  describe 'POST /events/:event_id/participations' do
    let!(:roomy_event) { create(:event, max_size: 10) }

    it '同じイベントに2回参加しても参加は1件のまま' do
      log_in(user)
      post event_participations_path(roomy_event)

      expect do
        post event_participations_path(roomy_event)
      end.not_to change(Participation, :count)
      expect(flash[:alert]).to be_present
    end

    it '二重参加では参加メールを送らない' do
      log_in(user)
      post event_participations_path(roomy_event)

      expect do
        post event_participations_path(roomy_event)
      end.not_to have_enqueued_mail(EventMailer, :participation_email)
    end
  end

  describe 'DELETE /events/:event_id/participations/:id' do
    let!(:participation) { create(:participation, event:, user:) }

    it '自分の参加をキャンセルできる' do
      log_in(user)

      expect do
        delete event_participation_path(event, participation)
      end.to change(Participation, :count).by(-1)
      expect(response).to redirect_to(event_path(event))
    end

    it 'キャンセルで空いた枠に他のユーザーが参加できる' do
      log_in(user)
      delete event_participation_path(event, participation)

      log_in(other_user)
      expect do
        post event_participations_path(event)
      end.to change(Participation, :count).by(1)
    end

    it '他人の参加はキャンセルできない' do
      log_in(other_user)

      expect do
        delete event_participation_path(event, participation)
      end.not_to change(Participation, :count)
    end

    it '未ログインではキャンセルできない' do
      expect do
        delete event_participation_path(event, participation)
      end.not_to change(Participation, :count)
    end
  end

  describe 'GET /events/:id' do
    it '参加済みならキャンセルボタンを表示し、参加ボタンを表示しない' do
      participation = create(:participation, event:, user:)
      log_in(user)

      get event_path(event)

      expect(response.body).to include('参加をキャンセルする')
      expect(response.body).to include(event_participation_path(event, participation))
      expect(response.body).not_to include('参加する</button>')
    end

    it 'キャンセル後は参加ボタンが表示される' do
      participation = create(:participation, event:, user:)
      log_in(user)
      delete event_participation_path(event, participation)

      get event_path(event)

      expect(response.body).not_to include('参加をキャンセルする')
      expect(response.body).to include('参加する</button>')
      expect(response.body).to include('参加人数: 0人')
    end
  end
end
