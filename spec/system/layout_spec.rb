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
    'イベント詳細（未ログイン）' => [ nil, -> { event_path(event) } ],
    'イベント詳細（参加者）' => [ :participant, -> { event_path(event) } ],
    'イベント詳細（主催者）' => [ :organizer, -> { event_path(event) } ],
    'イベント作成' => [ :organizer, -> { new_event_path } ],
    'マイページ' => [ :participant, -> { user_path } ],
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
