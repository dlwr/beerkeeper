class AddDiscordToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :discord_user_id, :string
    add_column :users, :discord_avatar, :string
    add_index :users, :discord_user_id, unique: true
  end
end
