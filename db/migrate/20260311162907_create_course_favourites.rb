class CreateCourseFavourites < ActiveRecord::Migration[8.1]
  def change
    create_table :course_favourites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end

    add_index :course_favourites, %i[user_id course_id], unique: true
  end
end
