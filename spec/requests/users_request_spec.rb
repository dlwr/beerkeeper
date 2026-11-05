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
end
