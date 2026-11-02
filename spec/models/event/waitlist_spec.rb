require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail

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

    it '補欠には参加メールではなく補欠のメールを送る' do
      expect { event.receive(second_user) }
        .to have_enqueued_mail(EventMailer, :waitlist_email)
        .and not_have_enqueued_mail(EventMailer, :participation_email)
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

    it '繰り上がったユーザーにメールを1通だけ送る' do
      expect { first_user.participations.find_by(event:).destroy }
        .to have_enqueued_mail(EventMailer, :promotion_email).with(params: { user: second_user, event: }, args: []).exactly(:once)
        .and have_enqueued_mail(EventMailer, :promotion_email).exactly(:once)
    end
  end

  describe '中止済みイベントでのキャンセル' do
    it '補欠を繰り上げない' do
      event.receive(first_user)
      event.receive(second_user)
      Event.find(event.id).cancel

      expect { first_user.participations.find_by(event:).destroy }
        .not_to have_enqueued_mail(EventMailer, :promotion_email)
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
        .not_to have_enqueued_mail(EventMailer, :promotion_email)

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
end
