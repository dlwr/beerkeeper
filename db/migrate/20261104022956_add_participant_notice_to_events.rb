class AddParticipantNoticeToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :participant_notice, :text
  end
end
