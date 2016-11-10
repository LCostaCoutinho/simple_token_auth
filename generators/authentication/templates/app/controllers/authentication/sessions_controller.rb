class Api::V1::Authentication::SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]


  def create
    @user = User.sign_in!(sign_in_params)
  end

  def destroy
    @user.sign_out!(request.headers['client'])
  end

  private

  def sign_in_params
    params.require(:email)
    params.require(:password)
    params.permit(:email,:password)
  end

  def omniauth_params
  end

end
