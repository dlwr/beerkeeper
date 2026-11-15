class RemovePasswordCredentials < ActiveRecord::Migration[8.1]
  def up
    orphan_users = "SELECT id FROM users WHERE discord_user_id IS NULL"
    orphan_events = "SELECT id FROM events WHERE organizer_id IN (#{orphan_users})"

    execute "DELETE FROM participations WHERE user_id IN (#{orphan_users}) OR event_id IN (#{orphan_events})"
    execute "DELETE FROM event_cancellations WHERE event_id IN (#{orphan_events})"
    execute "DELETE FROM events WHERE id IN (#{orphan_events})"
    drop_table :user_password_credentials
    execute "DELETE FROM users WHERE discord_user_id IS NULL"
    change_column_null :users, :discord_user_id, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
