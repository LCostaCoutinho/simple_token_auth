class AuthenticationGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration


  source_root File.expand_path('../templates', __FILE__)

  argument :class_name, :type => :string, :default => "User"

  def generate_layout

    directory "app/controllers/authentication", "app/controllers/api/v1/authentication"


    copy_file "app/models/concerns/authenticatable.rb", "app/models/concerns/authenticatable.rb"
    copy_file "app/models/authentication.rb", "app/models/authentication.rb"


    directory "lib/authentication_error", "lib/authentication_error"

    sub_file 'config/routes.rb', search = "Rails.application.routes.draw do", "#{search}\n\n#{route_code}\n"

    sub_file 'app/controllers/application_controller.rb', search = "protect_from_forgery with: :exception", "protect_from_forgery with: :null_session \n\n#{application_controller_code}\n"
    sub_file "app/models/#{file_name}.rb", search = "end \n\n#{application_controller_code}\n"



    copy_migration "create_authentications"

  end

  def self.next_migration_number(dir)
   Time.now.utc.strftime("%Y%m%d%H%M%S")
 end
  protected

  def copy_migration(filename)
    if self.class.migration_exists?("db/migrate", "#{filename}")
      say_status("skipped", "Migration #{filename}.rb already exists")
    else
      migration_template "db/migrate/#{filename}.rb", "db/migrate/#{filename}.rb"
    end
  end


  def route_code


<<RUBY

    namespace :api, defaults: {format: 'json'} do
      namespace :v1 do
        namespace :authentication do
          put 'omniauth/:provider' => 'omniauth#omniauth'
          patch 'omniauth/:provider' => 'omniauth#omniauth'
          post 'passwords' => 'passwords#create'
          patch 'passwords' => 'passwords#update'
          put 'passwords' => 'passwords#update'
          post 'registrations' => 'registrations#create'
          delete 'registrations' => 'registrations#destroy'
          post 'sessions' => 'sessions#create'
          delete 'sessions' => 'sessions#destroy'
        end
      end
    end

RUBY
  end

  def model_code

<<RUBY

    include Authenticatable

    def self.authentication_keys
      [:email]
    end
RUBY
  end




  def application_controller_code


<<RUBY

    after_action :build_response_headers

    rescue_from ActiveRecord::RecordInvalid do |exception|
      errors = exception.to_s.match(/\:(.*)/)
      errors = errors[1][1..errors[1].length].split(', ')
      render json: { errors: errors }, status: :unprocessable_entity
    end
    rescue_from ActiveRecord::RecordNotFound do |exception|
      render json: { errors: [exception.message]  }, status: :not_found
    end

    rescue_from ActionController::ParameterMissing do |exception|
      render json: { errors: [exception.message] }, status: :bad_request
    end

    rescue_from AuthenticationError::Unauthorized do |exception|
      render json: { errors: [exception.message] }, status: :unauthorized
    end

    rescue_from AuthenticationError::InvalidCredentials do |exception|
      render json: { errors: ['Dados inválidos!'] }, status: :unauthorized
    end



    def current_user
      return @user
    end

    def authenticate_user!
      @user = authenticate_user
      raise AuthenticationError::Unauthorized, 'Usuário não tem permissão de acesso.' if @user.nil?
    end

    def build_response_headers
      if @user.created_auth
        response.headers['uid']  = @user.uid
        response.headers['client']  = @user.created_auth.client
        response.headers['access-token']  = @user.created_auth.access_token
      else
        response.headers['uid'] = request.headers['uid']
        response.headers['client']  =  request.headers['client']
        response.headers['access-token']  = request.headers['access-token']
      end
    end

    private
    def authenticate_user
      user = User.authenticate_by_token(request.headers['uid'],request.headers['client'], request.headers['access-token'])
      unless user.nil?
        return user
      end
      return nil
    end

RUBY
  end

  private

  def destination_path(path)
    File.join(destination_root, path)
  end

  def sub_file(relative_file, search_text, replace_text)
    path = destination_path(relative_file)
    file_content = File.read(path)

    unless file_content.include? replace_text
      content = file_content.sub(/(#{Regexp.escape(search_text)})/mi, replace_text)
      File.open(path, 'wb') { |file| file.write(content) }
    end

    print "    \e[1m\e[31mmodified\e[0m\e[22m  #{relative_file}\n"

  end

    def file_name
    class_name.underscore
  end

end
