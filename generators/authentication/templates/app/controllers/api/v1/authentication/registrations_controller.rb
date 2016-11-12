class Api::V1::Authentication::RegistrationsController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:destroy]
  skip_after_action :build_response_headers, only: [:destroy]

  def create
    @user = User.create!(sign_up_params)
    bypass_authenticate(@user)
  end

  def destroy
    @user.destroy!
  end

  private

  def sign_up_params
    params.permit(:email,:password)
  end

end
