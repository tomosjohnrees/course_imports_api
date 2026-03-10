class CoursesController < ApplicationController
  before_action :authenticate_user!, except: :show

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
    redirect_to root_path, notice: "Course removed."
  end

  private

  def course_params
    params.require(:course).permit(:github_repo_url)
  end
end
