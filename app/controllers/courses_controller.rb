class CoursesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: %i[index show]

  def index
    @pagy, @courses = pagy(
      Course.publicly_visible.includes(:user).order(created_at: :desc),
      limit: 20
    )
  end

  def dashboard
    @pagy, @courses = pagy(current_user.courses.order(created_at: :desc), limit: 10)
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
    @course = Course.find(params[:id])
  end

  def destroy
    @course = current_user.courses.find(params[:id])
    @course.remove!
    redirect_to dashboard_courses_path, notice: "Course removed."
  end

  def resubmit
    @course = current_user.courses.find(params[:id])
    @course.resubmit!
    redirect_to @course, notice: "Course resubmitted for validation."
  rescue Course::Validatable::InvalidTransition
    redirect_to @course, alert: "Only failed courses can be resubmitted."
  end

  private

  def course_params
    params.require(:course).permit(:github_repo_url)
  end
end
