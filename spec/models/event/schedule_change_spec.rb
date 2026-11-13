require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:organizer) { create(:user) }
  let(:event) { create(:event, organizer:, max_size: 1, location: '三鷹', start_at: Time.zone.local(2099, 1, 15, 19, 0), end_at: Time.zone.local(2099, 1, 15, 21, 0)) }
  let(:participant) { create(:user) }
  let(:waitlister) { create(:user) }

  before do
    event.receive(participant)
    event.receive(waitlister)
  end

  describe '日時・場所の変更' do
    it '開催場所を変えると参加者と補欠に1通ずつ知らせる' do
      expect { event.update!(location: '吉祥寺') }
        .to have_enqueued_notification(:schedule_change).exactly(2)
        .and have_enqueued_notification(:schedule_change, participant, event, { 'location' => [ '三鷹', '吉祥寺' ] })
        .and have_enqueued_notification(:schedule_change, waitlister, event, { 'location' => [ '三鷹', '吉祥寺' ] })
    end

    it '開始日時と終了日時の変更も知らせる' do
      new_start = Time.zone.local(2099, 1, 22, 19, 0)
      new_end = Time.zone.local(2099, 1, 22, 21, 0)

      expect { event.update!(start_at: new_start, end_at: new_end) }
        .to have_enqueued_notification(:schedule_change).exactly(2)
        .and have_enqueued_notification(:schedule_change, participant, event, { 'start_at' => [ Time.zone.local(2099, 1, 15, 19, 0), new_start ], 'end_at' => [ Time.zone.local(2099, 1, 15, 21, 0), new_end ] })
    end

    it '主催者が参加していなければ主催者には送らない' do
      expect { event.update!(location: '吉祥寺') }
        .not_to have_enqueued_notification(:schedule_change, organizer, any_args)
    end

    it '定員と場所を同時に変えると、繰り上がった人には繰り上げと変更を1通ずつ送る' do
      expect { event.update!(max_size: 2, location: '吉祥寺') }
        .to have_enqueued_notification(:schedule_change).exactly(2)
        .and have_enqueued_notification(:promotion, waitlister, event).exactly(:once)
        .and have_enqueued_notification(:schedule_change, waitlister, event, { 'location' => [ '三鷹', '吉祥寺' ] }).exactly(:once)
    end

    it '日時・場所以外の変更では送らない' do
      expect { event.update!(name: '別の名前', description: '詳細', budget: '500') }
        .not_to have_enqueued_notification(:schedule_change)
    end

    it '保存に失敗したら送らない' do
      expect { event.update(location: '吉祥寺', name: '') }
        .not_to have_enqueued_notification(:schedule_change)
    end

    it '中止済みのイベントには送らない' do
      event.cancel
      cancelled = Event.find(event.id)

      expect { cancelled.update!(location: '吉祥寺') }
        .not_to have_enqueued_notification(:schedule_change)
    end
  end
end
