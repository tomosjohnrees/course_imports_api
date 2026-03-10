require "test_helper"

class CreateValidationAttemptsTest < ActiveSupport::TestCase
  setup do
    @connection = ActiveRecord::Base.connection
    @columns = @connection.columns(:validation_attempts).index_by(&:name)
    @indexes = @connection.indexes(:validation_attempts)
  end

  test "validation_attempts table exists" do
    assert @connection.table_exists?(:validation_attempts)
  end

  test "course_id is a non-nullable bigint with foreign key to courses" do
    column = @columns["course_id"]
    assert_equal :integer, column.type
    assert_not column.null

    foreign_keys = @connection.foreign_keys(:validation_attempts)
    course_fk = foreign_keys.find { |fk| fk.column == "course_id" }
    assert course_fk, "Expected foreign key on course_id"
    assert_equal "courses", course_fk.to_table
  end

  test "result is a nullable string" do
    column = @columns["result"]
    assert_equal :string, column.type
    assert column.null
  end

  test "error_message is a nullable text field" do
    column = @columns["error_message"]
    assert_equal :text, column.type
    assert column.null
  end

  test "api_calls_made is a nullable integer" do
    column = @columns["api_calls_made"]
    assert_equal :integer, column.type
    assert column.null
  end

  test "duration_ms is a nullable integer" do
    column = @columns["duration_ms"]
    assert_equal :integer, column.type
    assert column.null
  end

  test "created_at and updated_at timestamps exist and are non-nullable" do
    %w[created_at updated_at].each do |col_name|
      column = @columns[col_name]
      assert column, "Expected #{col_name} column to exist"
      assert_equal :datetime, column.type
      assert_not column.null, "Expected #{col_name} to be non-nullable"
    end
  end

  test "index on course_id" do
    index = @indexes.find { |i| i.columns == [ "course_id" ] }
    assert index, "Expected index on course_id"
  end

  test "inserting a validation attempt with valid course_id succeeds" do
    user = User.create!(github_id: "va-test-1", github_username: "vauser1")

    course_result = @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, status, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/va/test', 'va', 'test', 'VA Test', 'pending', NOW(), NOW())
      RETURNING id
    SQL
    course_id = course_result.first["id"]

    result = @connection.execute(<<~SQL)
      INSERT INTO validation_attempts (course_id, result, error_message, api_calls_made, duration_ms, created_at, updated_at)
      VALUES (#{course_id}, 'passed', NULL, 6, 1200, NOW(), NOW())
      RETURNING id
    SQL

    assert result.first["id"].present?
  end

  test "inserting a validation attempt with invalid course_id raises foreign key error" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      @connection.execute(<<~SQL)
        INSERT INTO validation_attempts (course_id, result, created_at, updated_at)
        VALUES (999999, 'failed', NOW(), NOW())
      SQL
    end
  end

  test "inserting a validation attempt without course_id raises not null error" do
    assert_raises(ActiveRecord::NotNullViolation) do
      @connection.execute(<<~SQL)
        INSERT INTO validation_attempts (result, created_at, updated_at)
        VALUES ('passed', NOW(), NOW())
      SQL
    end
  end

  test "multiple validation attempts can reference the same course" do
    user = User.create!(github_id: "va-test-2", github_username: "vauser2")

    course_result = @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, status, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/va/multi', 'va', 'multi', 'Multi VA', 'pending', NOW(), NOW())
      RETURNING id
    SQL
    course_id = course_result.first["id"]

    2.times do |i|
      @connection.execute(<<~SQL)
        INSERT INTO validation_attempts (course_id, result, api_calls_made, duration_ms, created_at, updated_at)
        VALUES (#{course_id}, 'attempt_#{i}', #{i + 1}, #{100 * (i + 1)}, NOW(), NOW())
      SQL
    end

    count_result = @connection.execute(<<~SQL)
      SELECT COUNT(*) as cnt FROM validation_attempts WHERE course_id = #{course_id}
    SQL

    assert_equal 2, count_result.first["cnt"]
  end
end
