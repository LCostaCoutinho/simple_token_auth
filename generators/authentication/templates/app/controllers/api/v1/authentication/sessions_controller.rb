class Api::V1::Authentication::SessionsController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:destroy]


  def create
    require_parameters([:auth, :password])
    sign_in!(params[:auth], params[:password])
  end

  def destroy
    sign_out
  end

end
