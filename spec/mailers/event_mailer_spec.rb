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
end
