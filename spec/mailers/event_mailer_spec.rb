require 'rails_helper'

RSpec.describe EventMailer, type: :mailer do
  describe 'participation_email' do
    let(:mail) { EventMailer.with(user:, event:).participation_email }
    let(:user) { FactoryBot.create(:user) }
    let(:event) { FactoryBot.create(:event) }

    it 'renders the headers' do
      expect(mail.subject).to eq("【#{event.name}】参加登録を受け付けました")
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to eq([ 'from@example.com' ])
    end

    it 'renders the body' do
      expect(mail.text_part.body.decoded).to match('ご参加登録いただき')
    end
  end

  describe 'cancellation_email' do
    let(:mail) { EventMailer.with(user:, event:).cancellation_email }
    let(:user) { FactoryBot.create(:user) }
    let(:event) { FactoryBot.create(:event) }

    before { event.cancel('会場が使えなくなったため') }

    it 'renders the headers' do
      expect(mail.subject).to eq("【#{event.name}】イベントは中止になりました")
      expect(mail.to).to eq([ user.email ])
    end

    it 'renders the reason in the body' do
      aggregate_failures do
        expect(mail.text_part.body.decoded).to match('中止')
        expect(mail.text_part.body.decoded).to match('会場が使えなくなったため')
        expect(mail.html_part.body.decoded).to match('会場が使えなくなったため')
      end
    end
  end

  describe 'waitlist_email' do
    let(:mail) { EventMailer.with(user:, event:).waitlist_email }
    let(:user) { FactoryBot.create(:user) }
    let(:event) { FactoryBot.create(:event) }

    it 'renders the headers and body' do
      aggregate_failures do
        expect(mail.subject).to eq("【#{event.name}】補欠として受け付けました")
        expect(mail.to).to eq([ user.email ])
        expect(mail.text_part.body.decoded).to match('補欠')
        expect(mail.html_part.body.decoded).to match('補欠')
      end
    end
  end

  describe 'promotion_email' do
    let(:mail) { EventMailer.with(user:, event:).promotion_email }
    let(:user) { FactoryBot.create(:user) }
    let(:event) { FactoryBot.create(:event) }

    it 'renders the headers and body' do
      aggregate_failures do
        expect(mail.subject).to eq("【#{event.name}】繰り上げで参加が確定しました")
        expect(mail.to).to eq([ user.email ])
        expect(mail.text_part.body.decoded).to match('繰り上げ')
        expect(mail.html_part.body.decoded).to match('繰り上げ')
      end
    end
  end
end
