require 'rails_helper'

RSpec.describe "ログインが要る操作", type: :request do
  let!(:organizer) { create(:user) }
  let!(:event) { create(:event, organizer:) }

  shared_examples 'ログイン画面へ誘導する' do
    it do
      subject

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq 'ログインしてください'
    end
  end

  describe 'GET /user' do
    subject { get user_path }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'GET /user/edit' do
    subject { get edit_user_path }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'PATCH /user' do
    subject { patch user_path, params: { user: { name: 'x' } } }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'GET /events/new' do
    subject { get new_event_path }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'POST /events' do
    subject { post events_path, params: { event: { name: 'x' } } }

    it_behaves_like 'ログイン画面へ誘導する'

    it 'イベントを作らない' do
      expect { subject }.not_to change(Event, :count)
    end
  end

  describe 'GET /events/:id/edit' do
    subject { get edit_event_path(event) }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'PATCH /events/:id' do
    subject { patch event_path(event), params: { event: { name: 'x' } } }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'DELETE /events/:id' do
    subject { delete event_path(event) }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'DELETE /events/:id/participations/:id' do
    let!(:participation) { create(:participation, event:, user: create(:user)) }

    subject { delete event_participation_path(event, participation) }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'POST /events/:id/participations' do
    subject { post event_participations_path(event) }

    it_behaves_like 'ログイン画面へ誘導する'
  end

  describe 'POST /events/:id/cancellations' do
    subject { post event_cancellations_path(event) }

    it_behaves_like 'ログイン画面へ誘導する'

    it 'イベントを中止しない' do
      expect { subject }.not_to change(Event::Cancellation, :count)
    end
  end

  describe 'ログインせずに開ける画面' do
    it 'イベント一覧・詳細、ログイン、サインアップ、パスワード再設定を開ける' do
      [ root_path, events_path, event_path(event), login_path, signup_path, new_password_reset_path ].each do |path|
        get path
        expect(response).to have_http_status(:ok), path
      end
    end
  end
end
