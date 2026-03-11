require "test_helper"

class CreateCourseLoadsTest < ActiveSupport::TestCase
  setup do
    @connection = ActiveRecord::Base.connection
    @columns = @connection.columns(:course_loads).index_by(&:name)
    @indexes = @connection.indexes(:course_loads)
  end

  test "course_loads table exists" do
    assert @connection.table_exists?(:course_loads)
  end

  test "course_id is a non-nullable bigint with foreign key to courses" do
    column = @columns["course_id"]
    assert_equal :integer, column.type
    assert_not column.null

    foreign_keys = @connection.foreign_keys(:course_loads)
    course_fk = foreign_keys.find { |fk| fk.column == "course_id" }
    assert course_fk, "Expected foreign key on course_id"
    assert_equal "courses", course_fk.to_table
  end

  test "identifier is a non-nullable string" do
    column = @columns["identifier"]
    assert_equal :string, column.type
    assert_not column.null
  end

  test "created_at is a non-nullable datetime" do
    column = @columns["created_at"]
    assert column, "Expected created_at column to exist"
    assert_equal :datetime, column.type
    assert_not column.null
  end

  test "unique composite index on course_id and identifier" do
    index = @indexes.find { |i| i.columns == %w[course_id identifier] }
    assert index, "Expected composite index on [course_id, identifier]"
    assert index.unique, "Expected the composite index to be unique"
  end

  test "index on course_id" do
    index = @indexes.find { |i| i.columns == [ "course_id" ] }
    assert index, "Expected index on course_id"
  end

  test "inserting a course load with valid data succeeds" do
    user = User.create!(github_id: "cl-schema-1", github_username: "clschema1")
    course = Course.create!(
      user: user,
      github_repo_url: "https://github.com/cl-schema/repo1",
      github_owner: "cl-schema",
      github_repo: "repo1",
      title: "Schema Test",
      status: "approved"
    )

    result = @connection.execute(<<~SQL)
      INSERT INTO course_loads (course_id, identifier, created_at)
      VALUES (#{course.id}, 'user_1', NOW())
      RETURNING id
    SQL

    assert result.first["id"].present?
  end

  test "inserting duplicate course_id and identifier raises uniqueness error" do
    user = User.create!(github_id: "cl-schema-2", github_username: "clschema2")
    course = Course.create!(
      user: user,
      github_repo_url: "https://github.com/cl-schema/repo2",
      github_owner: "cl-schema",
      github_repo: "repo2",
      title: "Dup Test",
      status: "approved"
    )

    @connection.execute(<<~SQL)
      INSERT INTO course_loads (course_id, identifier, created_at)
      VALUES (#{course.id}, 'user_1', NOW())
    SQL

    assert_raises(ActiveRecord::RecordNotUnique) do
      @connection.execute(<<~SQL)
        INSERT INTO course_loads (course_id, identifier, created_at)
        VALUES (#{course.id}, 'user_1', NOW())
      SQL
    end
  end

  test "inserting a course load with invalid course_id raises foreign key error" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      @connection.execute(<<~SQL)
        INSERT INTO course_loads (course_id, identifier, created_at)
        VALUES (999999, 'user_1', NOW())
      SQL
    end
  end

  test "inserting a course load without identifier raises not-null error" do
    user = User.create!(github_id: "cl-schema-3", github_username: "clschema3")
    course = Course.create!(
      user: user,
      github_repo_url: "https://github.com/cl-schema/repo3",
      github_owner: "cl-schema",
      github_repo: "repo3",
      title: "Null Test",
      status: "approved"
    )

    assert_raises(ActiveRecord::NotNullViolation) do
      @connection.execute(<<~SQL)
        INSERT INTO course_loads (course_id, created_at)
        VALUES (#{course.id}, NOW())
      SQL
    end
  end
end
