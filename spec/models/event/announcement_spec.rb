require "rails_helper"

RSpec.describe Event, type: :model do
  describe "#events への告知" do
    it "イベントを作ると1回だけ告知する" do
      expect { create(:event) }.to have_enqueued_job(EventAnnouncementJob).with("created", an_instance_of(Event)).exactly(:once)
    end

    it "作成に失敗したら告知しない" do
      expect { Event.create(name: "") }.not_to have_enqueued_job(EventAnnouncementJob)
    end

    it "更新では告知しない" do
      event = create(:event)

      expect { event.update!(name: "別の名前") }.not_to have_enqueued_job(EventAnnouncementJob)
    end

    it "中止したら中止を1回だけ告知する" do
      event = create(:event)

      expect { event.cancel("台風"); event.cancel }.to have_enqueued_job(EventAnnouncementJob).with("cancelled", event).exactly(:once)
    end
  end
end
