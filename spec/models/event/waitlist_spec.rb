require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:event) { create(:event, max_size: 1) }
  let(:first_user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:third_user) { create(:user) }

  describe '#receive when the event is full' do
    before { event.receive(first_user) }

    it '補欠として受け付ける' do
      participation = event.receive(second_user)

      aggregate_failures do
        expect(participation).to be_waitlisted
        expect(event.waitlisters).to eq [ second_user ]
      end
    end

    it '補欠は参加人数に数えない' do
      event.receive(second_user)

      aggregate_failures do
        expect(event.participants).to eq [ first_user ]
        expect(event.participants.size).to eq 1
      end
    end

    it '補欠には参加ではなく補欠の通知だけを送る' do
      expect { event.receive(second_user) }
        .to have_enqueued_notification(:waitlist)
        .and have_enqueued_job(EventNotificationJob).exactly(:once)
    end
  end

  describe '#waitlist_position' do
    it '申し込み順で何番目の補欠かを返す' do
      event.receive(first_user)
      event.receive(second_user)
      event.receive(third_user)

      aggregate_failures do
        expect(event.waitlist_position(second_user)).to eq 1
        expect(event.waitlist_position(third_user)).to eq 2
        expect(event.waitlist_position(first_user)).to be_nil
      end
    end
  end

  describe '参加者のキャンセル' do
    before do
      event.receive(first_user)
      event.receive(second_user)
      event.receive(third_user)
    end

    it '最も早い補欠が参加になる' do
      first_user.participations.find_by(event:).destroy

      aggregate_failures do
        expect(event.participants).to eq [ second_user ]
        expect(event.waitlisters).to eq [ third_user ]
      end
    end

    it '繰り上がったユーザーに通知を1通だけ送る' do
      expect { first_user.participations.find_by(event:).destroy }
        .to have_enqueued_notification(:promotion, second_user, event).exactly(:once)
        .and have_enqueued_notification(:promotion).exactly(:once)
    end
  end

  describe '中止済みイベントでのキャンセル' do
    it '補欠を繰り上げない' do
      event.receive(first_user)
      event.receive(second_user)
      Event.find(event.id).cancel

      expect { first_user.participations.find_by(event:).destroy }
        .not_to have_enqueued_notification(:promotion)
      expect(event.waitlisters).to eq [ second_user ]
    end
  end

  describe '補欠のキャンセル' do
    before do
      event.receive(first_user)
      event.receive(second_user)
      event.receive(third_user)
    end

    it '補欠自身もキャンセルでき、誰も繰り上がらない' do
      expect { second_user.participations.find_by(event:).destroy }
        .not_to have_enqueued_notification(:promotion)

      aggregate_failures do
        expect(event.participants).to eq [ first_user ]
        expect(event.waitlisters).to eq [ third_user ]
      end
    end
  end

  describe '定員を超えた参加' do
    it '定員を超えて参加になった申し込みは補欠に回す' do
      event.receive(first_user)
      allow(event).to receive(:full?).and_return(false)

      participation = event.receive(second_user)

      aggregate_failures do
        expect(participation).to be_waitlisted
        expect(event.participants).to eq [ first_user ]
      end
    end
  end

  describe '定員なし' do
    it '補欠にならない' do
      unlimited = create(:event, max_size: nil)

      expect(unlimited.receive(first_user)).not_to be_waitlisted
    end
  end

  describe '定員の変更' do
    before do
      event.receive(first_user)
      event.receive(second_user)
      event.receive(third_user)
    end

    it '定員を増やすと空いた分だけ補欠を先着順に繰り上げる' do
      event.update!(max_size: 2)

      aggregate_failures do
        expect(event.participants).to eq [ first_user, second_user ]
        expect(event.waitlisters).to eq [ third_user ]
      end
    end

    it '繰り上がったユーザーにだけメールを送る' do
      expect { event.update!(max_size: 2) }
        .to have_enqueued_notification(:promotion, second_user, event).exactly(:once)
        .and have_enqueued_notification(:promotion).exactly(:once)
    end

    it '定員を空にすると補欠が全員参加になる' do
      event.update!(max_size: nil)

      aggregate_failures do
        expect(event.participants).to eq [ first_user, second_user, third_user ]
        expect(event.waitlisters).to be_empty
      end
    end

    it '定員を減らしても参加者を補欠に戻さない' do
      event.update!(max_size: 3)
      event.update!(max_size: 1)

      aggregate_failures do
        expect(event.participants).to eq [ first_user, second_user, third_user ]
        expect(event.waitlisters).to be_empty
      end
    end

    it '定員以外の変更では繰り上げない' do
      expect { event.update!(name: '別の名前') }.not_to have_enqueued_notification(:promotion)
      expect(event.waitlisters).to eq [ second_user, third_user ]
    end

    it '保存に失敗したら繰り上げない' do
      expect { expect(event.update(max_size: 3, name: '')).to be false }
        .not_to have_enqueued_notification(:promotion)
      expect(Event.find(event.id).waitlisters).to eq [ second_user, third_user ]
    end

    it '補欠を読み込んだあとでも定員を増やせる' do
      event.waitlisters.load
      event.waitlisted_participations.load
      event.update!(max_size: 3)

      expect(Event.find(event.id).waitlisters).to be_empty
    end

    it '中止済みのイベントでは繰り上げない' do
      event.cancel
      Event.find(event.id).update!(max_size: 3)

      expect(event.waitlisters).to eq [ second_user, third_user ]
    end
  end
end
