class CourseFavouritesController < ApplicationController
  before_action :authenticate_user!

  def index
    scope = current_user.favourited_courses.approved.includes(:user).order("course_favourites.created_at DESC")
    @pagy, @courses = pagy(scope, limit: 20)
  end

  def create
    course = find_course
    current_user.course_favourites.create!(course: course)
    redirect_back fallback_location: course, notice: "Course added to favourites."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_back fallback_location: course, notice: "Course is already in your favourites."
  end

  def destroy
    course = find_course
    current_user.course_favourites.find_by!(course: course).destroy!
    redirect_back fallback_location: course, notice: "Course removed from favourites."
  end
end
