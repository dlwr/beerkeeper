require 'rails_helper'

RSpec.describe "Event::Cancellation", type: :request do
  let!(:user) { create(:user, password: 'password', password_confirmation: 'password') }
  let!(:event) { create(:event, organizer: user) }

  before do
    post sessions_path, params: { email: user.email, password: 'password' }
  end

  describe 'POST /events/:id/cancellations' do
    it 'Cancellationが作られる' do
      expect do
        post event_cancellations_path(event.id)
      end.to change(Event::Cancellation, :count).by(1)
    end

    it '入力した中止理由が保存される' do
      post event_cancellations_path(event.id), params: { cancellation: { reason: '台風のため' } }

      expect(event.reload.cancellation.reason).to eq '台風のため'
    end

    it '主催者以外のログインユーザーは中止できない' do
      other = create(:user)
      post sessions_path, params: { email: other.email, password: 'password' }

      expect do
        post event_cancellations_path(event.id)
      end.not_to change(Event::Cancellation, :count)
    end

    it '未ログインでは中止できない' do
      delete session_path(user)

      expect do
        post event_cancellations_path(event.id)
      end.not_to change(Event::Cancellation, :count)
    end
  end

  describe '中止後の表示' do
    let!(:participant) { create(:user) }

    before do
      create(:participation, event:, user: participant)
      event.cancel('台風のため')
      post sessions_path, params: { email: participant.email, password: 'password' }
    end

    it '詳細ページで中止と理由が表示される' do
      get event_path(event)

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('このイベントは中止されました')
        expect(response.body).to include('台風のため')
        expect(response.body).not_to include('参加をキャンセルする')
      end
    end

    it '一覧には表示されない' do
      get events_path

      expect(response.body).not_to include(event_path(event))
    end

    it '中止イベントには参加できない' do
      other = create(:user)
      post sessions_path, params: { email: other.email, password: 'password' }

      post event_participations_path(event)

      expect(event.participations.where(user: other)).not_to exist
    end

    it '中止イベントの参加はキャンセルできない' do
      participation = event.participations.find_by(user: participant)

      delete event_participation_path(event, participation)

      expect(Participation.exists?(participation.id)).to be true
    end
  end

  describe 'GET /events/:id（主催者）' do
    it '中止理由の入力欄を表示する' do
      get event_path(event)

      expect(response.body).to include('name="cancellation[reason]"')
    end
  end
end
