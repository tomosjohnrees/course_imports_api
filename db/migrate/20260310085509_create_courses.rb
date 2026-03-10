class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :github_repo_url, null: false
      t.string :github_owner, null: false
      t.string :github_repo, null: false
      t.string :external_id
      t.string :title, null: false
      t.text :description
      t.string :version
      t.string :author_name
      t.string :tags, array: true, default: []
      t.integer :topic_count
      t.string :status, null: false, default: "pending"
      t.text :validation_error
      t.integer :repo_size_kb
      t.datetime :last_validated_at
      t.integer :load_count, default: 0
      t.timestamps

      t.index %i[github_owner github_repo], unique: true
      t.index :status
      t.index :tags, using: :gin
    end
  end
end
