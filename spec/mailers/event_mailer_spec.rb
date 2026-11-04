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

  describe 'schedule_change_email' do
    let(:user) { FactoryBot.create(:user) }
    let(:event) { FactoryBot.create(:event, location: '吉祥寺') }
    let(:old_start) { Time.zone.local(2099, 1, 15, 19, 0) }
    let(:new_start) { Time.zone.local(2099, 1, 22, 19, 0) }
    let(:mail) { EventMailer.with(user:, event:, changes: { 'start_at' => [ old_start, new_start ], 'location' => [ '三鷹', '吉祥寺' ] }).schedule_change_email }

    it 'renders the headers' do
      expect(mail.subject).to eq("【#{event.name}】開催日時・場所が変更されました")
      expect(mail.to).to eq([ user.email ])
    end

    it '変わった項目の変更前と変更後、詳細の URL を本文に入れる' do
      [ mail.text_part.body.decoded, mail.html_part.body.decoded ].each do |body|
        aggregate_failures do
          expect(body).to include('開始日時', I18n.l(old_start), I18n.l(new_start))
          expect(body).to include('開催場所', '三鷹', '吉祥寺')
          expect(body).not_to include('終了日時')
          expect(body).to include("/events/#{event.id}")
        end
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
