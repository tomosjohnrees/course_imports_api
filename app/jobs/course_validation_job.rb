class CourseValidationJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: ->(course_id) { "course_validation_#{course_id}" }

  def perform(course_id)
    Course.find(course_id).run_validation!
  end
end
