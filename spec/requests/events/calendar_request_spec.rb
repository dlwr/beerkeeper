require 'rails_helper'

RSpec.describe 'Event calendar', type: :request do
  let!(:event) { create(:event, name: '次の定例会') }

  it 'ログインしていなくてもイベントを .ics で返す' do
    get event_path(event, format: :ics)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/calendar')
    expect(response.headers['Content-Disposition']).to include("event-#{event.id}.ics")
    expect(response.body).to include("SUMMARY:次の定例会\r\n")
    expect(response.body).to include("URL:#{event_url(event)}\r\n")
  end

  def google_link
    Nokogiri::HTML(response.body).css('main a').find { |a| a.text.strip == 'Google カレンダーに追加' }
  end

  it 'イベント詳細に .ics のリンクを出す' do
    get event_path(event)

    link = Nokogiri::HTML(response.body).css('main a').find { |a| a.text.strip == 'その他のカレンダー (.ics)' }
    expect(link['href']).to eq(event_path(event, format: :ics))
  end

  it 'イベント詳細に Google カレンダーの予定作成画面へのリンクを出す' do
    get event_path(event)

    expect(google_link['href']).to eq(Event::Calendar.new(event, url: event_url(event)).google_url)
  end

  it 'Google カレンダーへのリンクは別タブで開く' do
    get event_path(event)

    expect(google_link.to_h).to include('target' => '_blank', 'rel' => 'noopener')
  end

  it '終了したイベントにも Google カレンダーへのリンクを出す' do
    event.update!(start_at: 2.days.ago, end_at: 1.day.ago)

    get event_path(event)

    expect(google_link).to be_present
  end

  it '中止されたイベントには Google カレンダーへのリンクを出さない' do
    event.cancel

    get event_path(event)

    expect(google_link).to be_nil
  end

  it '中止されたイベントも CANCELLED として返す' do
    event.cancel

    get event_path(event, format: :ics)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("STATUS:CANCELLED\r\n")
  end
end
