class MoveCredentialsOutOfUsers < ActiveRecord::Migration[8.1]
  def up
    create_table :user_password_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :user_password_credentials, :email, unique: true

    execute <<~SQL
      INSERT INTO user_password_credentials (user_id, email, password_digest, created_at, updated_at)
      SELECT id, email, password_digest, created_at, updated_at FROM users
    SQL

    remove_index :users, :email
    remove_column :users, :email
    remove_column :users, :password_digest
  end

  def down
    add_column :users, :email, :string
    add_column :users, :password_digest, :string

    execute <<~SQL
      UPDATE users SET
        email = (SELECT email FROM user_password_credentials WHERE user_id = users.id),
        password_digest = (SELECT password_digest FROM user_password_credentials WHERE user_id = users.id)
    SQL

    change_column_null :users, :email, false
    change_column_null :users, :password_digest, false
    add_index :users, :email, unique: true
    drop_table :user_password_credentials
  end
end
