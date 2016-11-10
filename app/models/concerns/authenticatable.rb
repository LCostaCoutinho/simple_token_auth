module Authenticatable
	extend ActiveSupport::Concern

	included do
		has_many :authentications, as: :authable, dependent: :destroy

		validates_presence_of :provider
		validates :uid, presence: true, uniqueness: true

		attr_accessor :created_auth
	end

	module ClassMethods

		def sign_in!(auth_value, password, metadata={})
			resource = sign_in(auth_value, password, metadata)
			raise CustomException::Authentication::InvalidCredentials if resource.nil?
			return resource
		end

		def sign_in(auth_value, password, metadata={})
			resource = find_by_auth_values(auth_value)
			unless resource.nil?
				if resource.valid_password? password
					resource.created_auth = resource.authentications.create!(metadata: metadata)
					return resource
				end
			end
			return nil
		end

		def find_by_auth_values(auth_value)
			resource = nil
			authentication_keys.each do |auth_key|
				resource = send("find_by_#{auth_key}", auth_value)
				break if resource
			end
			return resource
		end

		def authenticate_by_token(uid, client, access_token)
			user = User.find_by_uid(uid)
			unless user.nil?
				authentication = user.authentications.find_by_client(client)
				if !authentication.nil?  and Authentication.token_compare(access_token, authentication.encrypted_access_token)
					return user
				end
			end
			return nil
		end

	end

	def update_with_password!(params)
		self.update_with_password(params) || raise(ActiveRecord::RecordInvalid.new(self))
	end

	def email=(em)
		if provider == "email"
			self.uid = em
		end
		super
	end

	def sign_out(client)
		auth  = self.authentications.find_by_client!(client)
		# raise CustomException::Authentication::InvalidClient if auth.nil?
		auth.destroy!
	end

end