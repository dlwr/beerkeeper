require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  let!(:user) { create(:user, email: 'member@example.com', password: 'oldpassword', password_confirmation: 'oldpassword') }

  describe 'GET /login' do
    it 'パスワードを忘れたときの導線を表示する' do
      get login_path

      expect(response.body).to include(new_password_reset_path)
    end
  end

  describe 'POST /password_resets' do
    it '登録済みのメールアドレスにリセット用のメールを送る' do
      expect do
        post password_resets_path, params: { email: 'member@example.com' }
      end.to have_enqueued_mail(UserMailer, :password_reset_email)

      expect(response).to redirect_to(login_path)
    end

    it '未登録のメールアドレスでも同じ応答を返し、メールは送らない' do
      post password_resets_path, params: { email: 'member@example.com' }
      registered_notice = flash[:notice]

      expect do
        post password_resets_path, params: { email: 'nobody@example.com' }
      end.not_to have_enqueued_mail(UserMailer, :password_reset_email)

      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq registered_notice
    end
  end

  describe 'GET /password_resets/:token/edit' do
    it '有効なトークンなら新しいパスワードの入力欄を表示する' do
      get edit_password_reset_path(user.password_reset_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('password_confirmation')
    end

    it '無効なトークンならリセットの申請画面に戻す' do
      get edit_password_reset_path('invalid')

      expect(response).to redirect_to(new_password_reset_path)
    end
  end

  describe 'PATCH /password_resets/:token' do
    let(:token) { user.password_reset_token }

    it '新しいパスワードを設定し、そのパスワードでログインできる' do
      patch password_reset_path(token), params: { password: 'newpassword', password_confirmation: 'newpassword' }

      expect(response).to redirect_to(login_path)

      post sessions_path, params: { email: user.email, password: 'newpassword' }
      expect(response).to redirect_to(events_path)
    end

    it '使用済みのトークンは無効になる' do
      patch password_reset_path(token), params: { password: 'newpassword', password_confirmation: 'newpassword' }
      patch password_reset_path(token), params: { password: 'another123', password_confirmation: 'another123' }

      expect(response).to redirect_to(new_password_reset_path)
      expect(user.reload.authenticate('newpassword')).to be_truthy
    end

    it '期限切れのトークンは無効になる' do
      token

      travel 16.minutes do
        patch password_reset_path(token), params: { password: 'newpassword', password_confirmation: 'newpassword' }
      end

      expect(response).to redirect_to(new_password_reset_path)
      expect(user.reload.authenticate('oldpassword')).to be_truthy
    end

    it '空のパスワードは受け付けない' do
      patch password_reset_path(token), params: { password: '', password_confirmation: '' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.authenticate('oldpassword')).to be_truthy
    end

    it '確認用と一致しないパスワードは受け付けない' do
      patch password_reset_path(token), params: { password: 'newpassword', password_confirmation: 'different' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.authenticate('oldpassword')).to be_truthy
    end
  end
end
