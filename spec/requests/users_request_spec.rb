require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { create(:user, email: 'before@example.com', password: 'password', password_confirmation: 'password') }

  before do
    post sessions_path, params: { email: 'before@example.com', password: 'password' }
  end

  describe 'PATCH /user' do
    it 'メールアドレスとパスワードを変えると、新しい組み合わせでログインできる' do
      patch user_path, params: { user: { name: user.name, email: 'after@example.com', password: 'newpassword', password_confirmation: 'newpassword' } }

      expect(response).to redirect_to(user_path)

      delete session_path(user)
      post sessions_path, params: { email: 'after@example.com', password: 'newpassword' }
      expect(response).to redirect_to(events_path)
    end

    it 'パスワードを空にすると今のパスワードのまま名前だけ変わる' do
      patch user_path, params: { user: { name: '新しい名前', email: 'before@example.com', password: '', password_confirmation: '' } }

      expect(user.reload.name).to eq '新しい名前'
      expect(user.authenticate('password')).to eq user
    end

    it '他の人のメールアドレスには変えられない' do
      create(:user, email: 'taken@example.com')

      patch user_path, params: { user: { name: user.name, email: 'taken@example.com' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.email).to eq 'before@example.com'
    end
  end

  describe 'GET /user' do
    let(:other) { create(:user) }

    def event_named(name, **attrs)
      create(:event, name:, **attrs)
    end

    it '参加登録した開催予定のイベントを開始日時順に並べ、補欠には補欠と出す' do
      later = event_named('あとの会', start_at: 3.days.from_now, end_at: 3.days.from_now + 1.hour)
      sooner = event_named('さきの会', start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
      create(:participation, event: later, user:, waitlisted: true)
      create(:participation, event: sooner, user:)

      get user_path

      body = response.body
      expect(body.index('さきの会')).to be < body.index('あとの会')
      expect(body).to include('補欠')
    end

    it '主催する開催予定のイベントを並べる' do
      event_named('自分の主催', organizer: user)

      get user_path

      expect(response.body).to include('自分の主催')
    end

    it '中止・終了したイベントと他人のイベントは出さない' do
      cancelled = event_named('中止の会', organizer: user)
      cancelled.cancel
      ended = event_named('終わった会', start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)
      create(:participation, event: ended, user:)
      others = event_named('他人の会', organizer: other)
      create(:participation, event: others, user: other)

      get user_path

      expect(response.body).not_to include('中止の会', '終わった会', '他人の会')
    end

    it '該当が無ければありませんと出す' do
      get user_path

      expect(response.body).to include('参加予定のイベントはありません', '主催するイベントはありません')
    end
  end

  describe 'ヘッダーのマイページへのリンク' do
    it 'ログイン中は出し、ログアウトすると出さない' do
      get root_path
      expect(response.body).to include(%(href="#{user_path}"))

      delete session_path(user)
      get root_path
      expect(response.body).not_to include(%(href="#{user_path}"))
    end
  end
end
