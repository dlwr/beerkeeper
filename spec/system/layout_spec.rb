require 'rails_helper'

RSpec.describe 'Layout', type: :system, js: true do
  let(:organizer) { create(:user, name: '主催者') }
  let(:participant) { create(:user, name: '参加者') }
  let!(:event) do
    create(:event, organizer:, name: '三鷹でビールを飲む会', location: '三鷹駅前', max_size: 10, budget: '3000',
                   description: '詳しくは当日に')
  end

  before do
    create(:participation, event:, user: participant)
  end

  def log_in_as(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user) { user }
  end

  screens = {
    'イベント一覧' => [ nil, -> { root_path } ],
    'イベント一覧（参加者）' => [ :participant, -> { root_path } ],
    'イベント詳細（未ログイン）' => [ nil, -> { event_path(event) } ],
    'イベント詳細（参加者）' => [ :participant, -> { event_path(event) } ],
    'イベント詳細（主催者）' => [ :organizer, -> { event_path(event) } ],
    'イベント作成' => [ :organizer, -> { new_event_path } ],
    'マイページ' => [ :participant, -> { user_path } ],
    'マイページ（主催者）' => [ :organizer, -> { user_path } ],
    '名前の編集' => [ :participant, -> { edit_user_path } ],
    'ログイン' => [ nil, -> { login_path } ]
  }

  screens.each do |name, (user, path)|
    [ 375, 1280 ].each do |width|
      it "#{name}は #{width}px で横スクロールが出ず、タップ範囲が 44px 以上ある", :discord do
        log_in_as(public_send(user)) if user
        resize_viewport(width)
        visit instance_exec(&path)

        expect(page.evaluate_script('window.innerWidth')).to eq(width)
        expect(horizontal_overflow).to be <= 0
        expect(small_tap_targets).to eq([])
      end
    end
  end

  context '開催中で補欠のイベントがあるマイページ' do
    let!(:ongoing_event) do
      create(:event, organizer:, name: '開催中の会', max_size: 1, start_at: 1.hour.ago, end_at: 2.hours.from_now)
    end

    before do
      create(:participation, event: ongoing_event, user: organizer)
      create(:participation, event: ongoing_event, user: participant, waitlisted: true)
    end

    [ 375, 1280 ].each do |width|
      it "#{width}px で横スクロールが出ず、印が出る" do
        log_in_as(participant)
        resize_viewport(width)
        visit user_path

        expect(page).to have_css('.event-row .seat-status', text: '開催中')
        expect(horizontal_overflow).to be <= 0
        expect(small_tap_targets).to eq([])
      end
    end
  end

  context '長い URL や英数字を入れたイベント' do
    let(:url) { "https://example.com/#{'a' * 120}" }
    let!(:long_event) do
      create(:event, organizer:, name: 'x' * 120, location: url, description: url, participant_notice: url)
    end
    let!(:cancelled_event) { create(:event, organizer:, name: 'y' * 120, location: url) }

    before do
      create(:participation, event: long_event, user: participant)
      cancelled_event.cancel('z' * 200)
    end

    {
      'イベント一覧' => [ nil, -> { root_path } ],
      'イベント詳細（参加者）' => [ :participant, -> { event_path(long_event) } ],
      'イベント詳細（主催者）' => [ :organizer, -> { event_path(long_event) } ],
      '中止したイベントの詳細' => [ nil, -> { event_path(cancelled_event) } ],
      'マイページ（長い場所）' => [ :participant, -> { user_path } ]
    }.each do |name, (user, path)|
      [ 375, 1280 ].each do |width|
        it "#{name}は #{width}px で横スクロールが出ない" do
          log_in_as(public_send(user)) if user
          resize_viewport(width)
          visit instance_exec(&path)

          expect(horizontal_overflow).to be <= 0
        end
      end
    end
  end

  context '場所と詳細に URL だけを入れたイベント' do
    let!(:link_event) do
      create(:event, organizer:, location: 'https://example.com/map', description: 'https://example.com/detail',
                     participant_notice: 'https://example.com/notice')
    end

    [ 375, 1280 ].each do |width|
      it "詳細は #{width}px で横スクロールが出ず、リンクのタップ範囲が 44px 以上ある" do
        log_in_as(organizer)
        resize_viewport(width)
        visit event_path(link_event)

        expect(page).to have_link('https://example.com/map', href: 'https://example.com/map')
        expect(horizontal_overflow).to be <= 0
        expect(small_tap_targets).to eq([])
      end
    end
  end

  context '過去のイベントが多いとき' do
    before do
      21.times do |i|
        day = Time.zone.local(2020, 1, 1) + i.days
        create(:event, organizer:, name: "過去の会#{i + 1}", start_at: day + 19.hours, end_at: day + 21.hours)
      end
    end

    {
      'イベント一覧' => [ -> { root_path }, '過去のイベントをすべて見る' ],
      '過去のイベント' => [ -> { past_events_path }, '古いイベント' ],
      '過去のイベントの 2 ページ目' => [ -> { past_events_path(page: 2) }, '新しいイベント' ],
      'マイページ' => [ -> { user_path }, '過去のイベントを見る' ]
    }.each do |name, (path, link)|
      [ 375, 1280 ].each do |width|
        it "#{name}は #{width}px で横スクロールが出ず、#{link}のタップ範囲が 44px 以上ある" do
          log_in_as(organizer)
          resize_viewport(width)
          visit instance_exec(&path)

          expect(page).to have_link(link)
          expect(horizontal_overflow).to be <= 0
          expect(small_tap_targets).to eq([])
        end
      end
    end
  end

  context '開催中のイベント' do
    let!(:ongoing_event) do
      create(:event, organizer:, name: '開催中の会', location: '三鷹駅前', max_size: 10,
                     start_at: 1.hour.ago, end_at: 2.hours.from_now)
    end

    {
      'イベント一覧' => -> { root_path },
      'イベント詳細' => -> { event_path(ongoing_event) }
    }.each do |name, path|
      [ 375, 1280 ].each do |width|
        it "#{name}は #{width}px で開催中と出し、横スクロールが出ない" do
          resize_viewport(width)
          visit instance_exec(&path)

          expect(page).to have_text('開催中')
          expect(horizontal_overflow).to be <= 0
        end
      end
    end
  end

  it '幅の広い要素があると横スクロールを検出する' do
    resize_viewport(375)
    visit root_path
    page.execute_script("document.querySelector('main').insertAdjacentHTML('beforeend', '<div style=\"width: 800px\">wide</div>')")

    expect(horizontal_overflow).to be > 0
  end

  it '小さいボタンがあるとタップ範囲の不足を検出する' do
    resize_viewport(375)
    visit root_path
    page.execute_script("document.querySelector('main').insertAdjacentHTML('beforeend', '<button style=\"height: 20px; padding: 0\">小さい</button>')")

    expect(small_tap_targets).to include(a_string_including('小さい'))
  end
end
