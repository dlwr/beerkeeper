require 'rails_helper'

RSpec.describe User::PasswordCredential, type: :model do
  it 'users にはメールアドレスとパスワードの列が無い' do
    expect(User.column_names).not_to include('email', 'password_digest')
  end

  it 'メールアドレスは大文字小文字を区別せず重複できない' do
    create(:user, email: 'member@example.com')
    user = build(:user, email: 'MEMBER@example.com')

    expect(user).not_to be_valid
    expect(user.errors.full_messages).to include('Email はすでに存在します')
  end

  it 'メールアドレスの形式が誤っていると登録できない' do
    user = build(:user, email: 'not-an-email')

    expect(user).not_to be_valid
    expect(user.errors.full_messages).to include('Email の形式が不正です')
  end

  it 'パスワードが無いと登録できない' do
    user = build(:user, password: nil, password_confirmation: nil)

    expect(user).not_to be_valid
    expect(user.errors.full_messages).to include('Password を入力してください')
  end

  it '登録すると利用者と認証情報が一緒に保存される' do
    user = create(:user, email: 'member@example.com', password: 'secret', password_confirmation: 'secret')

    expect(User.find_by_email('member@example.com')).to eq user
    expect(user.reload.authenticate('secret')).to eq user
    expect(user.authenticate('wrong')).to be_falsey
  end

  it 'パスワード再設定のトークンから利用者を引ける' do
    user = create(:user)

    expect(User.find_by_password_reset_token(user.password_reset_token)).to eq user
  end
end
