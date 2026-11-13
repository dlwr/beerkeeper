require 'rails_helper'

RSpec.describe Participation, type: :model do
  describe 'validations' do
    it '同じユーザーは同じイベントに2件参加できない' do
      participation = create(:participation, user: create(:user), event: create(:event))
      duplicate = build(:participation, user: participation.user, event: participation.event)

      aggregate_failures do
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end
    end

    it 'DB でも同じユーザーと同じイベントの組は1件に限られる' do
      participation = create(:participation, user: create(:user), event: create(:event))
      duplicate = build(:participation, user: participation.user, event: participation.event)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'after_create_commit callbacks' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }

    it '参加の通知を送る' do
      expect { create(:participation, user:, event:) }.to have_enqueued_notification(:participation)
    end
  end
end
