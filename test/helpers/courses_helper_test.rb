require "test_helper"

class CoursesHelperTest < ActionView::TestCase
  include CoursesHelper

  FakeCourse = Struct.new(:status)

  test "status_badge renders badge for each valid status" do
    %w[pending validating approved failed].each do |status|
      course = FakeCourse.new(status)
      result = status_badge(course)
      assert result.present?, "Expected badge for status '#{status}' but got nil"
    end
  end

  test "status_badge returns nil for unknown status" do
    course = FakeCourse.new("unknown")
    assert_nil status_badge(course)
  end

  test "STATUS_BADGES contains exactly four statuses" do
    assert_equal %w[pending validating approved failed], CoursesHelper::STATUS_BADGES.keys
  end
end
