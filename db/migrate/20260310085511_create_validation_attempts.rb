class CreateValidationAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :validation_attempts do |t|
      t.references :course, null: false, foreign_key: true
      t.string :result
      t.text :error_message
      t.integer :api_calls_made
      t.integer :duration_ms
      t.timestamps
    end
  end
end
