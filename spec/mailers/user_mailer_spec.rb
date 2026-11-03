require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'password_reset_email' do
    let(:user) { FactoryBot.create(:user) }
    let(:mail) { UserMailer.with(user:).password_reset_email }

    it 'renders the headers' do
      expect(mail.subject).to eq('パスワードの再設定')
      expect(mail.to).to eq([ user.email ])
    end

    it 'リセット用のリンクを含む' do
      expect(mail.text_part.body.decoded).to include('http://example.com/password_resets/')
      expect(mail.html_part.body.decoded).to include('http://example.com/password_resets/')
    end
  end
end
