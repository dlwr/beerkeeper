require 'rails_helper'

RSpec.describe Event::Calendar do
  let(:event) do
    create(:event,
           name: '定例会, 第1回; \\特別',
           location: "三鷹\n駅前",
           description: '詳細です',
           start_at: Time.zone.local(2099, 1, 15, 19, 30),
           end_at: Time.zone.local(2099, 1, 15, 21, 0))
  end
  let(:url) { "https://beerkeeper.example.com/events/#{event.id}" }
  let(:ics) { described_class.new(event, url:).to_ics }
  let(:lines) { ics.gsub(/\r\n[ \t]/, '').split("\r\n") }

  it 'VCALENDAR に 1 件の VEVENT を CRLF 改行で入れる' do
    expect(ics).to start_with("BEGIN:VCALENDAR\r\n")
    expect(ics).to end_with("END:VCALENDAR\r\n")
    expect(ics.scan("\n").size).to eq(ics.scan("\r\n").size)
    expect(lines).to include('VERSION:2.0', 'BEGIN:VEVENT', 'END:VEVENT')
    expect(lines.count('BEGIN:VEVENT')).to eq(1)
  end

  it '開始・終了日時を UTC で入れる' do
    expect(lines).to include('DTSTART:20990115T103000Z', 'DTEND:20990115T120000Z')
  end

  it '名前・場所・詳細をエスケープして入れ、詳細の末尾にイベントの URL を足す' do
    expect(lines).to include('SUMMARY:定例会\\, 第1回\; \\\\特別')
    expect(lines).to include('LOCATION:三鷹\\n駅前')
    expect(lines).to include("DESCRIPTION:詳細です\\n\\n#{url}")
    expect(lines).to include("URL:#{url}")
  end

  it 'UID はイベントごとに固定する' do
    uid = lines.grep(/\AUID:/).sole
    expect(uid).to eq("UID:event-#{event.id}@beerkeeper.example.com")
    expect(described_class.new(event.reload, url:).to_ics).to include(uid)
  end

  it '中止されていなければ CONFIRMED、中止されたら CANCELLED にする' do
    expect(lines).to include('STATUS:CONFIRMED')

    event.cancel
    cancelled = described_class.new(event.reload, url:).to_ics

    expect(cancelled).to include("STATUS:CANCELLED\r\n")
  end

  it '中止されたら DTSTAMP を中止の日時にする' do
    event
    travel_to(Time.zone.local(2099, 1, 1, 9, 0)) { event.cancel }

    cancelled = described_class.new(event.reload, url:).to_ics

    expect(cancelled).to include("DTSTAMP:20990101T000000Z\r\n")
  end

  it '75 オクテットを超える行は文字の途中で切らずに折り返す' do
    event.update!(description: 'あ' * 100)

    raw_lines = ics.split("\r\n")
    expect(raw_lines).to all(satisfy { |line| line.bytesize <= 75 })
    expect(raw_lines).to all(satisfy(&:valid_encoding?))
    expect(lines).to include("DESCRIPTION:#{'あ' * 100}\\n\\n#{url}")
  end

  it '場所と詳細が空なら詳細には URL だけを入れ、LOCATION は出さない' do
    event.update!(location: nil, description: nil)

    expect(lines.grep(/\ALOCATION/)).to be_empty
    expect(lines).to include("DESCRIPTION:#{url}")
  end

  describe '#google_url' do
    let(:google_url) { described_class.new(event, url:).google_url }
    let(:query) { Rack::Utils.parse_query(URI.parse(google_url).query) }

    it 'Google カレンダーの予定作成画面を指す' do
      expect(google_url).to start_with('https://calendar.google.com/calendar/render?')
      expect(query['action']).to eq('TEMPLATE')
    end

    it '名前をタイトルに入れる' do
      expect(query['text']).to eq('定例会, 第1回; \\特別')
    end

    it '開始・終了日時を UTC で入れる' do
      expect(query['dates']).to eq('20990115T103000Z/20990115T120000Z')
    end

    it '場所を入れる' do
      expect(query['location']).to eq("三鷹\n駅前")
    end

    it '詳細の末尾にイベントの URL を足す' do
      expect(query['details']).to eq("詳細です\n\n#{url}")
    end

    it '詳細が 500 文字を超えたら切り、イベントの URL は残す' do
      event.update!(description: 'あ' * 501)

      expect(query['details']).to eq("#{'あ' * 499}…\n\n#{url}")
    end

    it '詳細が空なら URL だけを入れる' do
      event.update!(description: nil)

      expect(query['details']).to eq(url)
    end

    it '場所が空なら location を付けない' do
      event.update!(location: nil)

      expect(query).not_to have_key('location')
    end
  end
end
