require 'rails_helper'

RSpec.describe "参加者向けのお知らせ", type: :request do
  let!(:organizer) { create(:user, password: 'password', password_confirmation: 'password') }
  let!(:participant) { create(:user, password: 'password', password_confirmation: 'password') }
  let!(:waitlister) { create(:user, password: 'password', password_confirmation: 'password') }
  let!(:stranger) { create(:user, password: 'password', password_confirmation: 'password') }
  let!(:event) { create(:event, organizer:, max_size: 1, participant_notice: '集合は改札前に19時') }

  before do
    event.receive(participant)
    event.receive(waitlister)
  end

  def log_in(user)
    post sessions_path, params: { email: user.email, password: 'password' }
  end

  describe 'GET /events/:id' do
    it '参加者には見せる' do
      log_in(participant)
      get event_path(event)

      expect(response.body).to include('参加者へのお知らせ', '集合は改札前に19時')
    end

    it '主催者には見せる' do
      log_in(organizer)
      get event_path(event)

      expect(response.body).to include('集合は改札前に19時')
    end

    it '補欠には見せない' do
      log_in(waitlister)
      get event_path(event)

      expect(response.body).not_to include('集合は改札前に19時')
    end

    it '参加していないユーザーには見せない' do
      log_in(stranger)
      get event_path(event)

      expect(response.body).not_to include('集合は改札前に19時')
    end

    it '未ログインでは見せない' do
      get event_path(event)

      expect(response.body).not_to include('集合は改札前に19時')
    end

    it '中止したイベントでは見せない' do
      event.cancel
      log_in(participant)
      get event_path(event)

      expect(response.body).not_to include('集合は改札前に19時')
    end

    it 'お知らせが無ければ見出しも出さない' do
      event.update!(participant_notice: '')
      log_in(participant)
      get event_path(event)

      expect(response.body).not_to include('参加者へのお知らせ')
    end
  end

  describe '主催者による登録' do
    it '編集画面にお知らせの入力欄がある' do
      log_in(organizer)
      get edit_event_path(event)

      expect(response.body).to include('event[participant_notice]')
    end

    it '主催者はお知らせを更新できる' do
      log_in(organizer)
      patch event_path(event), params: { event: { participant_notice: '会場が3階に変わりました' } }

      expect(event.reload.participant_notice).to eq '会場が3階に変わりました'
    end

    it '主催者以外は更新できない' do
      log_in(participant)
      patch event_path(event), params: { event: { participant_notice: 'いたずら' } }

      expect(event.reload.participant_notice).to eq '集合は改札前に19時'
    end
  end
end
