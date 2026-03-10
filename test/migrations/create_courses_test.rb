require "test_helper"

class CreateCoursesTest < ActiveSupport::TestCase
  setup do
    @connection = ActiveRecord::Base.connection
    @columns = @connection.columns(:courses).index_by(&:name)
    @indexes = @connection.indexes(:courses)
  end

  test "courses table exists" do
    assert @connection.table_exists?(:courses)
  end

  test "user_id is a non-nullable bigint with foreign key to users" do
    column = @columns["user_id"]
    assert_equal :integer, column.type
    assert_not column.null

    foreign_keys = @connection.foreign_keys(:courses)
    user_fk = foreign_keys.find { |fk| fk.column == "user_id" }
    assert user_fk, "Expected foreign key on user_id"
    assert_equal "users", user_fk.to_table
  end

  test "github_repo_url is a non-nullable string" do
    column = @columns["github_repo_url"]
    assert_equal :string, column.type
    assert_not column.null
  end

  test "github_owner is a non-nullable string" do
    column = @columns["github_owner"]
    assert_equal :string, column.type
    assert_not column.null
  end

  test "github_repo is a non-nullable string" do
    column = @columns["github_repo"]
    assert_equal :string, column.type
    assert_not column.null
  end

  test "external_id is a nullable string" do
    column = @columns["external_id"]
    assert_equal :string, column.type
    assert column.null
  end

  test "title is a non-nullable string" do
    column = @columns["title"]
    assert_equal :string, column.type
    assert_not column.null
  end

  test "description is a nullable text field" do
    column = @columns["description"]
    assert_equal :text, column.type
    assert column.null
  end

  test "version is a nullable string" do
    column = @columns["version"]
    assert_equal :string, column.type
    assert column.null
  end

  test "author_name is a nullable string" do
    column = @columns["author_name"]
    assert_equal :string, column.type
    assert column.null
  end

  test "tags is a string array defaulting to empty array" do
    column = @columns["tags"]
    assert_equal :string, column.type
    assert column.array
    assert_includes [ "{}", "'{}'::character varying[]" ], column.default
  end

  test "topic_count is a nullable integer" do
    column = @columns["topic_count"]
    assert_equal :integer, column.type
    assert column.null
  end

  test "status is a non-nullable string defaulting to pending" do
    column = @columns["status"]
    assert_equal :string, column.type
    assert_not column.null
    assert_equal "pending", column.default
  end

  test "validation_error is a nullable text field" do
    column = @columns["validation_error"]
    assert_equal :text, column.type
    assert column.null
  end

  test "repo_size_kb is a nullable integer" do
    column = @columns["repo_size_kb"]
    assert_equal :integer, column.type
    assert column.null
  end

  test "last_validated_at is a nullable datetime" do
    column = @columns["last_validated_at"]
    assert_equal :datetime, column.type
    assert column.null
  end

  test "load_count is an integer defaulting to 0" do
    column = @columns["load_count"]
    assert_equal :integer, column.type
    assert_includes [ 0, "0" ], column.default
  end

  test "created_at and updated_at timestamps exist and are non-nullable" do
    %w[created_at updated_at].each do |col_name|
      column = @columns[col_name]
      assert column, "Expected #{col_name} column to exist"
      assert_equal :datetime, column.type
      assert_not column.null, "Expected #{col_name} to be non-nullable"
    end
  end

  test "unique composite index on github_owner and github_repo" do
    index = @indexes.find { |i| i.columns == %w[github_owner github_repo] }
    assert index, "Expected composite index on [github_owner, github_repo]"
    assert index.unique, "Expected the composite index to be unique"
  end

  test "index on status" do
    index = @indexes.find { |i| i.columns == [ "status" ] }
    assert index, "Expected index on status"
  end

  test "GIN index on tags" do
    index = @indexes.find { |i| i.columns == [ "tags" ] }
    assert index, "Expected index on tags"
    assert_equal "gin", index.using.to_s
  end

  test "index on user_id" do
    index = @indexes.find { |i| i.columns == [ "user_id" ] }
    assert index, "Expected index on user_id"
  end

  test "inserting a course with all required fields succeeds" do
    user = User.create!(github_id: "schema-test-1", github_username: "schemauser")

    result = @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, status, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/owner/repo', 'owner', 'repo', 'My Course', 'pending', NOW(), NOW())
      RETURNING id
    SQL

    assert result.first["id"].present?
  end

  test "inserting a course without required github_repo_url raises database error" do
    user = User.create!(github_id: "schema-test-2", github_username: "schemauser2")

    assert_raises(ActiveRecord::NotNullViolation) do
      @connection.execute(<<~SQL)
        INSERT INTO courses (user_id, github_owner, github_repo, title, created_at, updated_at)
        VALUES (#{user.id}, 'owner', 'repo', 'My Course', NOW(), NOW())
      SQL
    end
  end

  test "inserting a course without required title raises database error" do
    user = User.create!(github_id: "schema-test-3", github_username: "schemauser3")

    assert_raises(ActiveRecord::NotNullViolation) do
      @connection.execute(<<~SQL)
        INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, created_at, updated_at)
        VALUES (#{user.id}, 'https://github.com/o/r', 'o', 'r', NOW(), NOW())
      SQL
    end
  end

  test "inserting duplicate github_owner and github_repo raises uniqueness error" do
    user = User.create!(github_id: "schema-test-4", github_username: "schemauser4")

    @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, status, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/dup/repo', 'dup', 'repo', 'First', 'pending', NOW(), NOW())
    SQL

    assert_raises(ActiveRecord::RecordNotUnique) do
      @connection.execute(<<~SQL)
        INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, status, created_at, updated_at)
        VALUES (#{user.id}, 'https://github.com/dup/repo', 'dup', 'repo', 'Second', 'pending', NOW(), NOW())
      SQL
    end
  end

  test "inserting a course with invalid user_id raises foreign key error" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      @connection.execute(<<~SQL)
        INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, status, created_at, updated_at)
        VALUES (999999, 'https://github.com/bad/fk', 'bad', 'fk', 'Bad FK', 'pending', NOW(), NOW())
      SQL
    end
  end

  test "status defaults to pending when not specified" do
    user = User.create!(github_id: "schema-test-5", github_username: "schemauser5")

    result = @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/def/status', 'def', 'status', 'Default Status', NOW(), NOW())
      RETURNING status
    SQL

    assert_equal "pending", result.first["status"]
  end

  test "load_count defaults to 0 when not specified" do
    user = User.create!(github_id: "schema-test-6", github_username: "schemauser6")

    result = @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/def/load', 'def', 'load', 'Default Load', NOW(), NOW())
      RETURNING load_count
    SQL

    assert_equal 0, result.first["load_count"]
  end

  test "tags defaults to empty array when not specified" do
    user = User.create!(github_id: "schema-test-7", github_username: "schemauser7")

    result = @connection.execute(<<~SQL)
      INSERT INTO courses (user_id, github_repo_url, github_owner, github_repo, title, created_at, updated_at)
      VALUES (#{user.id}, 'https://github.com/def/tags', 'def', 'tags', 'Default Tags', NOW(), NOW())
      RETURNING tags
    SQL

    assert_equal "{}", result.first["tags"]
  end
end
