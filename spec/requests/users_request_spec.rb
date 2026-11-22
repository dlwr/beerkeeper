require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { create(:user, name: '前の名前') }

  before do
    log_in(user)
  end

  describe 'GET /user/edit' do
    it '名前だけを編集でき、メールアドレスとパスワードの欄は無い' do
      get edit_user_path

      expect(response.body).to include('name="user[name]"')
      expect(response.body).not_to include('type="password"', 'type="email"', 'user[email]')
    end

    it '日本語のラベルと保存ボタンで、英語の文言を残さない' do
      get edit_user_path

      form = Nokogiri::HTML(response.body).at('main form')
      expect(form.at('label[for="user_name"]').text.squish).to eq '名前 必須'
      expect(form.at('input[type=submit]')['value']).to eq '保存'
      expect(form.text + form.css('input').map { |i| i['value'] }.join).not_to match(/Name|Update/)
      expect(form.at('#user_name')['autocomplete']).to eq 'nickname'
    end
  end

  describe 'PATCH /user' do
    it '名前を変えられる' do
      patch user_path, params: { user: { name: '新しい名前' } }

      expect(response).to redirect_to(user_path)
      expect(flash[:notice]).to eq 'ユーザー情報を更新しました'
      expect(user.reload.name).to eq '新しい名前'
    end

    it '名前が空なら欄の下にエラーを出す' do
      patch user_path, params: { user: { name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      html = Nokogiri::HTML(response.body)
      expect(html.at('#user_name')['aria-invalid']).to eq 'true'
      expect(html.at('#user_name_error').text).to eq '名前を入力してください'
    end

    it 'Discord のアカウントは変えられない' do
      patch user_path, params: { user: { name: user.name, discord_user_id: 'someone-else' } }

      expect(user.reload.discord_user_id).not_to eq 'someone-else'
    end
  end

  describe 'DELETE /user' do
    it '削除するとトップへ戻し、日本語で知らせる' do
      delete user_path

      expect(response).to redirect_to(root_url)
      expect(flash[:notice]).to eq 'ユーザーを削除しました'
      expect(User.exists?(user.id)).to be false
    end
  end

  describe 'GET /user' do
    let(:other) { create(:user) }

    def event_named(name, **attrs)
      create(:event, name:, **attrs)
    end

    it '参加登録した開催予定のイベントを開始日時順に並べ、補欠には補欠と出す' do
      later = event_named('あとの会', start_at: 3.days.from_now, end_at: 3.days.from_now + 1.hour)
      sooner = event_named('さきの会', start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
      create(:participation, event: later, user:, waitlisted: true)
      create(:participation, event: sooner, user:)

      get user_path

      body = response.body
      expect(body.index('さきの会')).to be < body.index('あとの会')
      expect(body).to include('補欠')
    end

    it '行に場所を出し、場所が空なら出さない' do
      placed = event_named('場所ありの会', location: '三鷹駅前', start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
      unplaced = event_named('場所なしの会', location: '', start_at: 3.days.from_now, end_at: 3.days.from_now + 1.hour)
      create(:participation, event: placed, user:)
      create(:participation, event: unplaced, user:)

      get user_path

      rows = Nokogiri::HTML(response.body).css('.event-row')
      row = ->(name) { rows.find { |r| r.at('.event-row__name').text == name } }
      expect(row.call('場所ありの会').at('.event-row__where').text).to eq '三鷹駅前'
      expect(row.call('場所なしの会').at('.event-row__where')).to be_nil
    end

    it '名前の編集画面へのリンクを出す' do
      get user_path

      link = Nokogiri::HTML(response.body).at(%(main a[href="#{edit_user_path}"]))
      expect(link.text.strip).to eq '名前を編集'
    end

    it '各イベントを行全体のリンクにし、名前を日時より先に出す' do
      event = event_named('さきの会', start_at: Time.zone.local(2099, 1, 15, 19, 30), end_at: Time.zone.local(2099, 1, 15, 21, 0))
      create(:participation, event:, user:)

      get user_path

      row = Nokogiri::HTML(response.body).at(%(main a.event-row[href="#{event_path(event)}"]))
      expect(row.element_children.first.text.strip).to eq 'さきの会'
      expect(row.text).to include('2099年1月15日(木)', '19:30〜21:00')
    end

    it '主催する開催予定のイベントを並べる' do
      event_named('自分の主催', organizer: user)

      get user_path

      expect(response.body).to include('自分の主催')
    end

    def section(title)
      body = response.body
      start = body.index(title)
      rest = body[(start + title.length)..]
      stop = rest.index('<h2') || rest.length
      rest[0...stop]
    end

    it '中止された主催イベント・終了したイベント・他人のイベントは参加予定に出さず、終了したイベントと他人のイベントは主催に出さない' do
      cancelled = event_named('中止の会', organizer: user)
      cancelled.cancel
      ended = event_named('終わった会', start_at: 2.days.ago, end_at: 2.days.ago + 1.hour, organizer: user)
      create(:participation, event: ended, user:)
      others = event_named('他人の会', organizer: other)
      create(:participation, event: others, user: other)

      get user_path

      expect(section('参加予定のイベント')).not_to include('中止の会', '終わった会', '他人の会')
      expect(section('主催するイベント')).not_to include('終わった会', '他人の会')
    end

    it '主催する開催予定のイベントが中止されたら、主催に中止と出す' do
      event_named('中止した主催の会', organizer: user).cancel

      get user_path

      organizing = section('主催するイベント')
      expect(organizing).to include('中止した主催の会')
      expect(organizing).to match(/>\s*中止\s*</)
    end

    it '終了した主催イベントを新しい順に主催したイベントに並べ、中止したものには中止と出す' do
      older = event_named('前々回の主催', start_at: 30.days.ago, end_at: 30.days.ago + 1.hour, organizer: user)
      newer = event_named('前回の主催', start_at: 2.days.ago, end_at: 2.days.ago + 1.hour, organizer: user)
      cancelled = event_named('取りやめた主催', start_at: 10.days.ago, end_at: 10.days.ago + 1.hour, organizer: user)
      cancelled.cancel
      event_named('開催予定の主催', organizer: user)
      event_named('他人の過去の主催', start_at: 5.days.ago, end_at: 5.days.ago + 1.hour, organizer: other)

      get user_path

      organized = section('主催したイベント')
      expect(organized.index('前回の主催')).to be < organized.index('取りやめた主催')
      expect(organized.index('取りやめた主催')).to be < organized.index('前々回の主催')
      expect(organized).to match(/>\s*中止\s*</)
      expect(organized).not_to include('開催予定の主催', '他人の過去の主催')
    end

    it '参加していた開催予定のイベントが中止されたら、参加予定に中止と出す' do
      event = event_named('中止になった会')
      create(:participation, event:, user:)
      event.cancel

      get user_path

      upcoming = section('参加予定のイベント')
      expect(upcoming).to include('中止になった会')
      expect(upcoming).to match(/>\s*中止\s*</)
    end

    it '補欠でなく参加した終了済みのイベントを、新しい順に参加したイベントに並べる' do
      older = event_named('前々回', start_at: 30.days.ago, end_at: 30.days.ago + 1.hour)
      newer = event_named('前回', start_at: 2.days.ago, end_at: 2.days.ago + 1.hour)
      waitlisted = event_named('補欠だった会', start_at: 3.days.ago, end_at: 3.days.ago + 1.hour)
      cancelled = event_named('中止された過去の会', start_at: 4.days.ago, end_at: 4.days.ago + 1.hour)
      others = event_named('他人だけの過去の会', start_at: 5.days.ago, end_at: 5.days.ago + 1.hour)
      create(:participation, event: older, user:)
      create(:participation, event: newer, user:)
      create(:participation, event: waitlisted, user:, waitlisted: true)
      create(:participation, event: cancelled, user:)
      create(:participation, event: others, user: other)
      cancelled.cancel

      get user_path

      past = section('参加したイベント')
      expect(past.index('前回')).to be < past.index('前々回')
      expect(past).not_to include('補欠だった会', '中止された過去の会', '他人だけの過去の会')
    end

    it '該当が無ければありませんと出す' do
      get user_path

      expect(response.body).to include('参加予定のイベントはありません', '主催するイベントはありません', '主催したイベントはありません', '参加したイベントはありません')
    end
  end

  describe 'ヘッダーのマイページへのリンク' do
    it 'ログイン中は出し、ログアウトすると出さない' do
      get root_path
      expect(response.body).to include(%(href="#{user_path}"))

      delete session_path(user)
      get root_path
      expect(response.body).not_to include(%(href="#{user_path}"))
    end
  end
end
