require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'validations' do
    describe 'name' do
      let!(:event) { FactoryBot.build(:event, name: name) }

      context '文字が入力されている場合' do
        let!(:name) { 'イベント名' }

        it { expect(event).to be_valid }
      end

      context '空文字の場合' do
        let!(:name) { '' }

        it { expect(event).to be_invalid }
      end
    end

    describe 'start_at and end_at' do
      context 'start_atがend_atより前の場合' do
        let(:event) { FactoryBot.build(:event, start_at: Time.current, end_at: Time.current + 1.hour) }

        it { expect(event).to be_valid }
      end

      context 'start_atがend_atと同じ場合' do
        let(:now) { Time.current }
        let(:event) { FactoryBot.build(:event, start_at: now, end_at: now) }

        it { expect(event).to be_invalid }
      end

      context 'start_atがend_atより後の場合' do
        let(:event) { FactoryBot.build(:event, start_at: Time.current + 1.hour, end_at: Time.current) }

        it { expect(event).to be_invalid }
      end
    end
  end

  describe '#copy' do
    it '日時と主催者を除いた内容を持つ保存前のイベントを返す' do
      source = create(:event, name: '定例会', location: '三鷹', max_size: 20, budget: '1000',
                              description: '説明', participant_notice: 'お知らせ')

      copied = source.copy

      expect(copied).to be_new_record
      expect(copied.attributes.slice('name', 'location', 'max_size', 'budget', 'description', 'participant_notice'))
        .to eq('name' => '定例会', 'location' => '三鷹', 'max_size' => 20, 'budget' => '1000',
               'description' => '説明', 'participant_notice' => 'お知らせ')
      expect(copied.start_at).to be_nil
      expect(copied.end_at).to be_nil
      expect(copied.organizer_id).to be_nil
    end
  end

  describe '#organized_by?' do
    let!(:event) { FactoryBot.create(:event) }

    context '引数がnilの場合' do
      it { expect(event.organized_by?(nil)).to be_falsey }
    end

    context '引数がオーガナイザーの場合' do
      it { expect(event.organized_by?(event.organizer)).to be_truthy }
    end

    context '引数がオーガナイザーでない場合' do
      let!(:user) { FactoryBot.create(:user) }

      it { expect(event.organized_by?(user)).to be_falsey }
    end
  end

  describe '#full?' do
    context 'when the number of participants is less than the max_size' do
      let(:event) { FactoryBot.create(:event, max_size: 2) }
      it { expect(event).not_to be_full }
    end

    context 'when the number of participants is greater than the max_size' do
      let(:event) { FactoryBot.create(:event, max_size: 2) }

      before do
        event.max_size.times do
          FactoryBot.create(:participation, user: FactoryBot.create(:user), event:)
        end
      end

      it { expect(event).to be_full }
    end

    context 'when max_size is null' do
      let(:event) { FactoryBot.create(:event, max_size: nil) }

      before do
        5.times do
          FactoryBot.create(:participation, user: FactoryBot.create(:user), event:)
        end
      end

      it { expect(event).not_to be_full }
    end
  end

  describe '#receive' do
    let(:event) { FactoryBot.create(:event, max_size: 2) }
    let(:user) { FactoryBot.create(:user) }

    context 'when the event is not full' do
      it { expect(event.receive(user)).to be_truthy }
    end

    context 'when the event is full' do
      before do
        event.max_size.times do
          FactoryBot.create(:participation, user: FactoryBot.create(:user), event:)
        end
      end

      it { expect(event.receive(user)).to be_waitlisted }
    end
  end

  describe "#receive twice by the same user" do
    it "2回目は参加を作らず、メールも送らない" do
      event = FactoryBot.create(:event)
      user = FactoryBot.create(:user)
      event.receive(user)

      aggregate_failures do
        expect { expect(event.receive(user)).to be_falsey }.not_to have_enqueued_notification(:participation)
        expect(Participation.where(event:, user:).count).to eq 1
      end
    end
  end

  describe "#receive on a cancelled event" do
    it "中止済みなら参加を作らない" do
      event = FactoryBot.create(:event)
      user = FactoryBot.create(:user)
      Event.find(event.id).cancel

      aggregate_failures do
        expect(event.receive(user)).to be_falsey
        expect(Participation.where(event_id: event.id)).not_to exist
      end
    end
  end

  describe "#ended?" do
    it "終了日時を過ぎていれば終了している" do
      event = FactoryBot.build(:event, start_at: 2.hours.ago, end_at: 1.hour.ago)

      expect(event).to be_ended
    end

    it "開催中なら終了していない" do
      event = FactoryBot.build(:event, start_at: 1.hour.ago, end_at: 1.hour.from_now)

      expect(event).not_to be_ended
    end
  end

  describe "#receive on an ended event" do
    it "終了済みなら参加を作らない" do
      event = FactoryBot.create(:event, start_at: 2.hours.ago, end_at: 1.hour.ago)
      user = FactoryBot.create(:user)

      aggregate_failures do
        expect(event.receive(user)).to be_nil
        expect(Participation.where(event_id: event.id)).not_to exist
      end
    end
  end

  describe "#promote_waitlisters on an ended event" do
    it "終了済みなら定員を増やしても補欠を繰り上げない" do
      event = FactoryBot.create(:event, start_at: 2.hours.ago, end_at: 1.hour.ago, max_size: 1)
      FactoryBot.create(:participation, event:, user: FactoryBot.create(:user))
      waitlisted = FactoryBot.create(:participation, event:, user: FactoryBot.create(:user), waitlisted: true)

      expect do
        event.update!(max_size: 2)
      end.not_to have_enqueued_notification(:promotion)
      expect(waitlisted.reload).to be_waitlisted
    end
  end

  describe ".not_cancelled" do
    let!(:event) { FactoryBot.create(:event) }
    let!(:cancelled_event) do
      event = FactoryBot.create(:event)
      event.cancel
      event
    end

    it "中止されたeventを除外する" do
      aggregate_failures do
        expect(Event.not_cancelled).to include event
        expect(Event.not_cancelled).not_to include cancelled_event
      end
    end

    it "Event.all は中止されたeventも含む" do
      expect(Event.all).to include cancelled_event
    end
  end
end
