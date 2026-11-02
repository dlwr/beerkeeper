require 'rails_helper'

RSpec.describe Event::Cancellable, type: :model do
  let(:event) { FactoryBot.create(:event) }

  context 'when the event is not cancelled' do
    it { expect(event).not_to be_cancelled }
    it { expect(event.cancelled_at).to be_nil }
  end

  context 'when the event is cancelled' do
    before { event.cancel }

    it { expect(event).to be_cancelled }
    it { expect(event.cancelled_at).to eq Event::Cancellation.last.created_at }
  end

  describe '#cancel' do
    it 'cancels the event' do
      expect { event.cancel }.to change(event, :cancelled?).to(true)
    end

    it 'can receive a reason' do
      reason = 'Weather is bad'
      cancellation = event.cancel(reason)
      expect(cancellation.reason).to eq reason
    end

    context 'when the event is already cancelled' do
      before { event.cancel }
      it { expect(event.cancel).to be_nil }
    end

    context 'when the event has participants' do
      let(:participants) { FactoryBot.create_list(:user, 2) }

      before do
        participants.each { |user| FactoryBot.create(:participation, event:, user:) }
      end

      it 'sends a cancellation email to each participant' do
        expect { event.cancel('台風') }
          .to have_enqueued_mail(EventMailer, :cancellation_email).exactly(2).times
      end

      it 'sends a cancellation email to waitlisted users too' do
        FactoryBot.create(:participation, event:, user: FactoryBot.create(:user), waitlisted: true)

        expect { event.cancel('台風') }
          .to have_enqueued_mail(EventMailer, :cancellation_email).exactly(3).times
      end

      it 'does not send emails again when cancelled twice' do
        event.cancel
        expect { event.cancel }.not_to have_enqueued_mail(EventMailer, :cancellation_email)
      end
    end
  end
end
