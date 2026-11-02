class AddWaitlistedToParticipations < ActiveRecord::Migration[8.1]
  def change
    add_column :participations, :waitlisted, :boolean, default: false, null: false
  end
end
