require 'rails_helper'

RSpec.describe "イベントをもとにした新規作成", type: :request do
  let!(:user) { create(:user, password: 'password', password_confirmation: 'password') }
  let!(:source) do
    create(:event, organizer: user, name: 'mitaka.rb 定例会', location: '三鷹市 某所', max_size: 20, budget: '1000',
                   description: 'Ruby の話をする会', participant_notice: '受付は 2 階です',
                   start_at: Time.zone.local(2026, 3, 14, 18, 30), end_at: Time.zone.local(2026, 3, 14, 21, 0))
  end

  def log_in(account)
    post sessions_path, params: { email: account.email, password: 'password' }
  end

  def form_section
    response.body.split('<h1>新規作成</h1>').last
  end

  describe 'GET /events/new?source_id=' do
    it '主催者が自分のイベントを指定すると、日時以外を入れたフォームを出す' do
      log_in(user)

      get new_event_path(source_id: source.id)

      expect(response).to have_http_status(:ok)
      expect(form_section).to include('value="mitaka.rb 定例会"')
      expect(form_section).to include('value="三鷹市 某所"')
      expect(form_section).to include('value="20"')
      expect(form_section).to include('value="1000"')
      expect(form_section).to include('Ruby の話をする会')
      expect(form_section).to include('受付は 2 階です')
      expect(form_section).not_to include('value="2026-03-14"')
      expect(form_section).not_to include('value="18:30"')
      expect(form_section).to include(%(action="#{events_path}"))
    end

    it '中止したイベントももとにできる' do
      log_in(user)
      source.cancel

      get new_event_path(source_id: source.id)

      expect(form_section).to include('value="mitaka.rb 定例会"')
    end

    it '他人のイベントを指定すると空のフォームを出す' do
      other = create(:user, password: 'password', password_confirmation: 'password')
      log_in(other)

      get new_event_path(source_id: source.id)

      expect(response).to have_http_status(:ok)
      expect(form_section).not_to include('mitaka.rb 定例会')
      expect(form_section).not_to include('受付は 2 階です')
    end

    it '存在しないイベントを指定すると空のフォームを出す' do
      log_in(user)

      get new_event_path(source_id: Event.maximum(:id).to_i + 1)

      expect(response).to have_http_status(:ok)
      expect(form_section).not_to include('mitaka.rb 定例会')
    end
  end

  describe '詳細のリンク' do
    let(:link) { %(href="#{new_event_path(source_id: source.id)}") }

    it '主催者には出す' do
      log_in(user)

      get event_path(source)

      expect(response.body).to include(link)
    end

    it '終了・中止したイベントでも主催者には出す' do
      log_in(user)
      source.cancel

      get event_path(source)

      expect(response.body).to include(link)
    end

    it '主催者以外には出さない' do
      log_in(create(:user, password: 'password', password_confirmation: 'password'))

      get event_path(source)

      expect(response.body).not_to include(link)
    end

    it '未ログインには出さない' do
      get event_path(source)

      expect(response.body).not_to include(link)
    end
  end

  it 'もとにして保存すると新しいイベントができ、元のイベントと参加者は変わらない' do
    create(:participation, event: source, user: create(:user))
    log_in(user)

    expect do
      post events_path, params: {
        event: { start_at_date: '2099-04-11', start_at_time: '18:30', end_at_date: '2099-04-11', end_at_time: '21:00',
                 name: source.name, location: source.location, max_size: source.max_size }
      }
    end.to change(Event, :count).by(1)

    created = Event.order(:id).last
    expect(created.participations).to be_empty
    expect(source.reload.participations.count).to eq(1)
    expect(source.start_at).to eq(Time.zone.local(2026, 3, 14, 18, 30))
  end
end
