require 'rails_helper'

RSpec.describe Event, type: :model do
  let!(:later) { create(:event, name: 'later', start_at: 3.days.from_now, end_at: 3.days.from_now + 1.hour) }
  let!(:sooner) { create(:event, name: 'sooner', start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour) }
  let!(:ongoing) { create(:event, name: 'ongoing', start_at: 1.hour.ago, end_at: 1.hour.from_now) }
  let!(:old) { create(:event, name: 'old', start_at: 10.days.ago, end_at: 10.days.ago + 1.hour) }
  let!(:recent) { create(:event, name: 'recent', start_at: 2.days.ago, end_at: 2.days.ago + 1.hour) }

  let(:created) { Event.where(id: [ later, sooner, ongoing, old, recent ].map(&:id)) }

  describe '.upcoming' do
    it '終わっていないイベントを開始日時の昇順で返す' do
      expect(created.upcoming.map(&:name)).to eq %w[ongoing sooner later]
    end
  end

  describe '.past' do
    it '終わったイベントを開始日時の新しい順で返す' do
      expect(created.past.map(&:name)).to eq %w[recent old]
    end
  end
end
