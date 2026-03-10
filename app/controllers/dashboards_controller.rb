class DashboardsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  def show
    @pagy, @courses = pagy(current_user.courses.order(created_at: :desc), limit: 10)
  end
end
