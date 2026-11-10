require 'rails_helper'

RSpec.describe "Events", type: :request do
  let!(:user) { create(:user, password: 'password', password_confirmation: 'password') }

  before do
    post sessions_path, params: { email: user.email, password: 'password' }
  end

  describe 'GET /events' do
    let!(:upcoming_event) { create(:event, name: '次の定例会', start_at: Time.zone.local(2099, 1, 15, 19, 30), end_at: Time.zone.local(2099, 1, 15, 21, 0)) }
    let!(:past_event) { create(:event, name: '前の定例会', start_at: Time.zone.local(2020, 1, 15, 19, 30), end_at: Time.zone.local(2020, 1, 15, 21, 0)) }

    it '開催日時を表示し、開催予定と過去のイベントを分けて表示する' do
      get events_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(I18n.l(upcoming_event.start_at))
      expect(body).to include(I18n.l(past_event.start_at))
      expect(body).to include('開催予定')
      expect(body).to include('過去のイベント')
      expect(body.index('次の定例会')).to be < body.index('過去のイベント')
      expect(body.index('過去のイベント')).to be < body.index('前の定例会')
    end
  end

  describe 'GET /events/:id' do
    let!(:event) { create(:event, organizer: user) }
    let!(:other_user) { create(:user) }

    it '主催者にはイベント中止リンクを表示する' do
      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('イベント中止')
      expect(response.body).to include(event_cancellations_path(event))
    end

    it '主催者以外にはイベント中止リンクを表示しない' do
      post sessions_path, params: { email: other_user.email, password: 'password' }

      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('イベント中止')
      expect(response.body).not_to include(event_cancellations_path(event))
    end

    it '定員が空なら定員なしと表示する' do
      event.update!(max_size: nil)

      get event_path(event)

      expect(response.body).to include('参加人数: 0人（定員なし）')
      expect(response.body).not_to include('/ 人')
    end

    it '定員があれば参加人数と定員を表示する' do
      event.update!(max_size: 10)

      get event_path(event)

      expect(response.body).to include('参加人数: 0人 / 10人')
    end

    it '参加費が空なら未定と表示する' do
      event.update!(budget: '')

      get event_path(event)

      expect(response.body).to include('参加費: 未定')
    end

    it '参加費が数字だけなら円を付けて表示する' do
      event.update!(budget: '1000')

      get event_path(event)

      expect(response.body).to include('参加費: 1000円')
    end

    it '参加費が数字以外を含めば入力のまま表示する' do
      event.update!(budget: '無料')

      get event_path(event)

      expect(response.body).to include('参加費: 無料')
      expect(response.body).not_to include('無料円')
    end
  end

  describe 'POST /events' do
    it '日付と時刻の入力を開始日時と終了日時として保存する' do
      expect do
        post events_path, params: {
          event: {
            start_at_date: '2026-03-14',
            start_at_time: '18:30',
            end_at_date: '2026-03-14',
            end_at_time: '21:00',
            name: 'ホワイトデー会'
          }
        }
      end.to change(Event, :count).by(1)

      event = Event.order(:id).last
      expect(event.start_at).to eq(Time.zone.local(2026, 3, 14, 18, 30))
      expect(event.end_at).to eq(Time.zone.local(2026, 3, 14, 21, 0))
      expect(response).to redirect_to(event_path(event))
    end

    it 'イベント名が未入力のときはエラー内容を表示する' do
      post events_path, params: {
        event: {
          start_at_date: '2026-03-14',
          start_at_time: '18:30',
          end_at_date: '2026-03-14',
          end_at_time: '21:00',
          name: ''
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('イベント名')
      expect(response.body).to include('value="2026-03-14"')
      expect(response.body).to include('value="18:30"')
      expect(response.body).to include('value="21:00"')
    end
  end

  describe 'PATCH /events/:id' do
    let!(:event) { create(:event, organizer: user, start_at: Time.zone.local(2026, 3, 14, 18, 30), end_at: Time.zone.local(2026, 3, 14, 21, 0)) }

    it '日付と時刻の入力で開始日時と終了日時を更新する' do
      patch event_path(event), params: {
        event: {
          start_at_date: '2026-04-01',
          start_at_time: '19:00',
          end_at_date: '2026-04-01',
          end_at_time: '22:00'
        }
      }

      expect(response).to redirect_to(event_path(event))

      event.reload
      expect(event.start_at).to eq(Time.zone.local(2026, 4, 1, 19, 0))
      expect(event.end_at).to eq(Time.zone.local(2026, 4, 1, 22, 0))
    end
  end
end
