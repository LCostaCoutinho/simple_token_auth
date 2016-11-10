class Api::V1::Authentication::PasswordsController < ApplicationController
  before_action :authenticate_user!, only: [:update]
  skip_after_action :build_response_headers, only: [:create]

  def create
    User.send_recovery_password_email!(password_recovery_params)
  end

  def update
    @user.update_with_password!(password_chage_params)
  end

  private

  def password_recovery_params
    params.require(:email)
    params.permit(:email)
  end

  def password_chage_params
    params.permit(:current_password, :password, :password_confirmation)
  end
end
