class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def destroy
    current_user.destroy!
    reset_session
    redirect_to root_path, notice: "Your account has been deleted."
  end
end
