class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :github_id,       null: false
      t.string  :github_username,  null: false
      t.string  :github_token
      t.string  :display_name
      t.string  :avatar_url
      t.boolean :banned,           default: false, null: false
      t.timestamps
    end

    add_index :users, :github_id, unique: true
  end
end
