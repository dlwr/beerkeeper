require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe 'GET /signup' do
    it '入力欄をコンテナの外に出す余分な閉じタグがない' do
      get signup_path

      form = response.body[/<form.*?<\/form>/m]
      expect(form.scan('<div').size).to eq form.scan('</div>').size
    end
  end

  describe 'POST /signup' do
    let(:params) do
      { user: { name: 'なまえ', email: 'new@example.com', password: 'password', password_confirmation: 'password' } }
    end

    it '登録に成功するとログイン済みでイベント一覧へ移動する' do
      post signup_path, params: params

      expect(response).to redirect_to(events_path)
      follow_redirect!
      expect(response.body).to include('ユーザー登録しました')
      expect(response.body).to include('ログアウト')
    end

    it '入力に誤りがあるとサインアップ画面のままエラーを表示する' do
      post signup_path, params: { user: params[:user].merge(email: '') }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Email を入力してください')
    end
  end
end
