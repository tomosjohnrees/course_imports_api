class AddSearchVectorToCourses < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE courses
      ADD COLUMN search_vector tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B')
      ) STORED;
    SQL

    add_index :courses, :search_vector, using: :gin
  end

  def down
    remove_index :courses, :search_vector
    remove_column :courses, :search_vector
  end
end
