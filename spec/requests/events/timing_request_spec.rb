require 'rails_helper'

RSpec.describe "今日と開催中の印", type: :request do
  let!(:today_event) do
    create(:event, name: '今日の会', start_at: Time.zone.local(2030, 5, 10, 19, 30), end_at: Time.zone.local(2030, 5, 10, 21, 30))
  end
  let!(:tomorrow_event) do
    create(:event, name: '明日の会', start_at: Time.zone.local(2030, 5, 11, 19, 30), end_at: Time.zone.local(2030, 5, 11, 21, 30))
  end

  def item_when(event)
    Nokogiri::HTML(response.body).at(%(a.event-item[href="#{event_path(event)}"] .event-item__when)).text.squish
  end

  it '始まる前の今日のイベントには、一覧と詳細に今日と出す' do
    travel_to Time.zone.local(2030, 5, 10, 12, 0) do
      get events_path
      expect(item_when(today_event)).to include('今日')
      expect(item_when(today_event)).not_to include('開催中')
      expect(item_when(tomorrow_event)).not_to include('今日')

      get event_path(today_event)
      expect(event_fact('日時')).to include('今日')

      get event_path(tomorrow_event)
      expect(event_fact('日時')).not_to include('今日')
    end
  end

  it '開始から終了までは開催中と出し、今日は出さない' do
    travel_to Time.zone.local(2030, 5, 10, 20, 0) do
      get events_path
      expect(item_when(today_event)).to include('開催中')
      expect(item_when(today_event)).not_to include('今日')

      get event_path(today_event)
      expect(event_fact('日時')).to include('開催中')
    end
  end

  it '終了したイベントと中止したイベントには出さない' do
    travel_to Time.zone.local(2030, 5, 10, 22, 0) do
      get event_path(today_event)
      expect(event_fact('日時')).not_to include('開催中')
      expect(event_fact('日時')).not_to include('今日')
    end

    today_event.cancel('雨')
    travel_to Time.zone.local(2030, 5, 10, 20, 0) do
      get event_path(today_event)
      expect(event_fact('日時')).not_to include('開催中')
    end
  end

  describe 'マイページ' do
    let(:user) { create(:user) }
    let!(:organizing_event) do
      create(:event, name: '主催の会', organizer: user, start_at: Time.zone.local(2030, 5, 10, 19, 0), end_at: Time.zone.local(2030, 5, 10, 22, 0))
    end

    before do
      create(:participation, event: today_event, user:)
      create(:participation, event: tomorrow_event, user:)
      log_in(user)
    end

    def row_marks(event)
      Nokogiri::HTML(response.body).css(%(a.event-row[href="#{event_path(event)}"] .seat-status)).map { _1.text.squish }
    end

    it '始まる前の今日の参加予定に今日と出し、明日のイベントには出さない' do
      travel_to Time.zone.local(2030, 5, 10, 12, 0) do
        get user_path
        expect(row_marks(today_event)).to include('今日')
        expect(row_marks(tomorrow_event)).not_to include('今日')
      end
    end

    it '開催中の参加予定と主催予定に開催中と出し、今日は出さない' do
      travel_to Time.zone.local(2030, 5, 10, 20, 0) do
        get user_path
        expect(row_marks(today_event)).to include('開催中')
        expect(row_marks(today_event)).not_to include('今日')
        expect(row_marks(organizing_event)).to include('開催中')
      end
    end

    it '中止したイベントには中止だけを出す' do
      today_event.cancel('雨')
      travel_to Time.zone.local(2030, 5, 10, 20, 0) do
        get user_path
        expect(row_marks(today_event)).to include('中止')
        expect(row_marks(today_event)).not_to include('開催中')
      end
    end
  end
end
