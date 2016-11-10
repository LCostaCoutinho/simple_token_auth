class Api::V1::Authentication::SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]
  before_action :sign_in_params, only: [:create]


  def create
    @user = User.sign_in!(params[:auth],params[:password])
  end

  def destroy
    @user.sign_out!(request.headers['client'])
  end

  private

  def sign_in_params
    params.require(:auth)
    params.require(:password)
  end

  def omniauth_params
  end

end
