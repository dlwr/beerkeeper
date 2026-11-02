class AddUniqueIndexToParticipations < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      DELETE FROM participations
      WHERE id NOT IN (
        SELECT MIN(id) FROM participations GROUP BY event_id, user_id
      )
    SQL
    add_index :participations, %i[event_id user_id], unique: true
  end

  def down
    remove_index :participations, %i[event_id user_id]
  end
end
