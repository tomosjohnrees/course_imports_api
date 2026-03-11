class CoursesController < ApplicationController
  include Pagy::Method

  before_action :authenticate_user!, except: %i[index show track_load]

  def index
    @search_query = params[:q]
    @tag = params[:tag]&.strip&.downcase.presence
    scope = Course.publicly_visible.search(@search_query).with_tag(@tag).includes(:user)
    scope = scope.order(created_at: :desc) if @search_query.blank?
    @pagy, @courses = pagy(scope, limit: 20)
  end

  def new
    @course = Course.new
  end

  def create
    @course = current_user.courses.build(course_params)

    if @course.save
      @course.submit_for_validation!
      redirect_to @course, notice: "Course submitted! Validation is in progress."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @course = find_course
    raise ActiveRecord::RecordNotFound unless @course.viewable_by?(current_user)

    expires_in 5.minutes, public: true if @course.approved?
  end

  def destroy
    @course = find_current_user_course
    @course.destroy!
    redirect_to dashboard_path, notice: "Course removed."
  end

  def track_load
    course = find_course
    identifier = current_user ? "user_#{current_user.id}" : "session_#{session.id}"
    course.record_load(identifier)
    head :no_content
  end

  def resubmit
    @course = find_current_user_course
    @course.resubmit!
    redirect_to @course, notice: "Course resubmitted for validation."
  rescue Course::Validatable::InvalidTransition
    redirect_to @course, alert: "Only failed courses can be resubmitted."
  end

  private

  def find_course
    Course.find_by!(github_owner: params[:github_owner], github_repo: params[:github_repo])
  end

  def find_current_user_course
    current_user.courses.find_by!(github_owner: params[:github_owner], github_repo: params[:github_repo])
  end

  def course_params
    params.require(:course).permit(:github_repo_url)
  end
end
