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

  it 'イベント詳細にカレンダーに追加するリンクを出す' do
    get event_path(event)

    expect(response.body).to include('カレンダーに追加')
    expect(response.body).to include(event_path(event, format: :ics))
  end

  it '中止されたイベントも CANCELLED として返す' do
    event.cancel

    get event_path(event, format: :ics)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("STATUS:CANCELLED\r\n")
  end
end
