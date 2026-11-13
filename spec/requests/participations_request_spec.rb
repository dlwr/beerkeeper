require 'rails_helper'

RSpec.describe "Participations", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:event) { create(:event, max_size: 1) }

  def log_in(user)
    post sessions_path, params: { email: user.email, password: 'password' }
  end

  describe 'POST /events/:event_id/participations' do
    let!(:roomy_event) { create(:event, max_size: 10) }

    it '同じイベントに2回参加しても参加は1件のまま' do
      log_in(user)
      post event_participations_path(roomy_event)

      expect do
        post event_participations_path(roomy_event)
      end.not_to change(Participation, :count)
      expect(flash[:alert]).to be_present
    end

    it '二重参加では参加メールを送らない' do
      log_in(user)
      post event_participations_path(roomy_event)

      expect do
        post event_participations_path(roomy_event)
      end.not_to have_enqueued_notification(:participation)
    end
  end

  describe '補欠' do
    before { create(:participation, event:, user: other_user) }

    it '定員に達したイベントへの申し込みは補欠として受け付ける' do
      log_in(user)

      expect do
        post event_participations_path(event)
      end.to change(Participation, :count).by(1)
      expect(flash[:success]).to include('補欠')
    end

    it 'イベント詳細で参加者と補欠を分け、自分が補欠の何番目か表示する' do
      log_in(user)
      post event_participations_path(event)

      get event_path(event)

      aggregate_failures do
        expect(response.body).to include('参加人数: 1人')
        expect(response.body).to include('補欠リスト')
        expect(response.body).to include('補欠の1番目')
      end
    end

    it '参加者がキャンセルすると補欠が参加になる' do
      log_in(user)
      post event_participations_path(event)

      log_in(other_user)
      delete event_participation_path(event, other_user.participations.find_by(event:))

      expect(event.participants).to eq [ user ]
    end
  end

  describe 'DELETE /events/:event_id/participations/:id' do
    let!(:participation) { create(:participation, event:, user:) }

    it '自分の参加をキャンセルできる' do
      log_in(user)

      expect do
        delete event_participation_path(event, participation)
      end.to change(Participation, :count).by(-1)
      expect(response).to redirect_to(event_path(event))
    end

    it 'キャンセルで空いた枠に他のユーザーが参加できる' do
      log_in(user)
      delete event_participation_path(event, participation)

      log_in(other_user)
      expect do
        post event_participations_path(event)
      end.to change(Participation, :count).by(1)
    end

    it '他人の参加はキャンセルできない' do
      log_in(other_user)

      expect do
        delete event_participation_path(event, participation)
      end.not_to change(Participation, :count)
    end

    it '未ログインではキャンセルできない' do
      expect do
        delete event_participation_path(event, participation)
      end.not_to change(Participation, :count)
    end
  end

  describe '終了したイベント' do
    let!(:ended_event) { create(:event, start_at: 2.hours.ago, end_at: 1.hour.ago, max_size: 1) }

    it '参加登録できない' do
      log_in(user)

      expect do
        post event_participations_path(ended_event)
      end.not_to change(Participation, :count)
      expect(flash[:alert]).to eq 'イベントに参加できませんでした'
    end

    it '参加をキャンセルできず、補欠も繰り上がらない' do
      participation = create(:participation, event: ended_event, user:)
      create(:participation, event: ended_event, user: other_user, waitlisted: true)
      log_in(user)

      expect do
        delete event_participation_path(ended_event, participation)
      end.not_to have_enqueued_notification(:promotion)
      aggregate_failures do
        expect(Participation.exists?(participation.id)).to be true
        expect(ended_event.participants).to eq [ user ]
        expect(flash[:alert]).to eq 'イベント参加をキャンセルできませんでした'
      end
    end

    it '詳細画面に参加・キャンセルのボタンを出さず、終了したと表示する' do
      create(:participation, event: ended_event, user:)
      log_in(user)

      get event_path(ended_event)

      aggregate_failures do
        expect(response.body).to include('このイベントは終了しました')
        expect(response.body).not_to include('参加をキャンセルする')
        expect(response.body).not_to include('参加する</button>')
      end
    end

    it '未参加でも参加ボタンを出さない' do
      log_in(other_user)

      get event_path(ended_event)

      expect(response.body).not_to include('参加する</button>')
    end
  end

  describe '開催中のイベント' do
    let!(:ongoing_event) { create(:event, start_at: 1.hour.ago, end_at: 1.hour.from_now) }

    it '参加登録とキャンセルができる' do
      log_in(user)

      expect do
        post event_participations_path(ongoing_event)
      end.to change(Participation, :count).by(1)
      expect do
        delete event_participation_path(ongoing_event, user.participations.find_by(event: ongoing_event))
      end.to change(Participation, :count).by(-1)
    end
  end

  describe 'GET /events/:id' do
    it '参加済みならキャンセルボタンを表示し、参加ボタンを表示しない' do
      participation = create(:participation, event:, user:)
      log_in(user)

      get event_path(event)

      expect(response.body).to include('参加をキャンセルする')
      expect(response.body).to include(event_participation_path(event, participation))
      expect(response.body).not_to include('参加する</button>')
    end

    it 'キャンセル後は参加ボタンが表示される' do
      participation = create(:participation, event:, user:)
      log_in(user)
      delete event_participation_path(event, participation)

      get event_path(event)

      expect(response.body).not_to include('参加をキャンセルする')
      expect(response.body).to include('参加する</button>')
      expect(response.body).to include('参加人数: 0人')
    end
  end
end
