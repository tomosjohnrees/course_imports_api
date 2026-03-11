class CreateCourseLoads < ActiveRecord::Migration[8.1]
  def change
    create_table :course_loads do |t|
      t.references :course, null: false, foreign_key: true
      t.string :identifier, null: false

      t.datetime :created_at, null: false
    end

    add_index :course_loads, [ :course_id, :identifier ], unique: true
  end
end
