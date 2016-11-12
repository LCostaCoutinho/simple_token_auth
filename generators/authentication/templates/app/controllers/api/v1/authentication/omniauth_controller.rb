class Api::V1::Authentication::OmniauthController < Api::V1::BaseController

  def omniauth
    if params[:provider].downcase == 'facebook'
      @user = User.facebook_sign_in!(omniauth_params)
    elsif params[:provider].downcase == 'google_oauth2'
      @user = User.google_plus_sign_in!(omniauth_params)
    else
      raise AuthenticationError::ProviderNotSuported
    end
  end
  private

  def omniauth_params
    params.permit(:oauth_access_token,:provider, :email)
  end

end
