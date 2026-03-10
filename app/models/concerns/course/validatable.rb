module Course::Validatable
  extend ActiveSupport::Concern

  def submit_for_validation!
    return false unless pending? || failed?
    CourseValidationJob.perform_later(id)
  end

  def run_validation!(github_client: nil)
    return unless pending? || failed?

    update!(status: :validating)

    result = perform_validation(github_client)
    apply_validation_result(result)
    record_validation_attempt(result)
    broadcast_validation_status
  end

  private

  def perform_validation(github_client)
    client = github_client || GithubClient.new(token: user.github_token)
    Timeout.timeout(30) { CourseValidation.new(course: self, github_client: client).call }
  rescue Timeout::Error
    CourseValidation::Result.new("success?": false, metadata: nil, error: "Validation timed out — please try again later", api_calls: 0, duration_ms: 30_000)
  rescue StandardError => e
    Rails.logger.error("Course validation error for course #{id}: #{e.class} - #{e.message}")
    CourseValidation::Result.new("success?": false, metadata: nil, error: "An unexpected error occurred during validation", api_calls: 0, duration_ms: 0)
  end

  def apply_validation_result(result)
    if result.success?
      metadata = result.metadata
      update!(
        status: :approved,
        external_id: metadata[:course_id],
        title: metadata[:title],
        description: metadata[:description],
        version: metadata[:version],
        author_name: metadata[:author],
        tags: metadata[:tags],
        topic_count: metadata[:topic_count],
        last_validated_at: Time.current,
        validation_error: nil
      )
    else
      update!(status: :failed, validation_error: result.error)
    end
  end

  def record_validation_attempt(result)
    validation_attempts.create!(
      result: result.success? ? "success" : "failure",
      error_message: result.error,
      api_calls_made: result.api_calls,
      duration_ms: result.duration_ms
    )
  end

  def broadcast_validation_status
    broadcast_replace_to(
      "course_#{id}",
      target: "course_#{id}",
      partial: "courses/status",
      locals: { course: self }
    )
  end
end
