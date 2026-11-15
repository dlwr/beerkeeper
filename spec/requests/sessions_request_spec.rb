require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe 'GET /login' do
    it 'Discord でログインのボタンだけを出し、メールアドレスとパスワードの欄は出さない', :discord do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Discord でログイン')
      expect(response.body).not_to include('type="password"', 'name="email"', 'パスワードを忘れた場合')
    end

    it 'Discord のシークレットが無い環境では、ログインできないことを知らせる', :without_discord do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Discord でのログインが設定されていません')
    end
  end

  describe 'メールアドレスとパスワードの経路' do
    it 'サインアップ・パスワード再設定・パスワードでのログインは無い' do
      get '/signup'
      expect(response).to have_http_status(:not_found)

      get '/password_resets/new'
      expect(response).to have_http_status(:not_found)

      post '/sessions', params: { email: 'a@example.com', password: 'password' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /sessions/:id' do
    let!(:user) { create(:user) }

    it 'ログアウトして login にリダイレクトし、ログインリンクが表示される' do
      log_in(user)
      expect(response).to redirect_to(events_path)

      delete session_path(user)
      expect(response).to redirect_to(login_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('ログイン')
      expect(response.body).not_to include('ログアウト', 'サインアップ')
    end

    it 'ログアウトするとセッション ID が変わり、ログイン状態が消える' do
      log_in(user)
      before_id = session.id.to_s

      delete session_path(user)

      aggregate_failures do
        expect(session.id.to_s).not_to eq before_id
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
