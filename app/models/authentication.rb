class Authentication < ApplicationRecord
  # Associations  
  belongs_to :authable, polymorphic: true

  # Validations
  validates_presence_of :authable

  # Serializations
  serialize :metadata, Hash

  # Virtual Attributes
  attr_accessor :raw_access_token

  # Callbacks
  before_create :generate_authentication_tokens

  # Callback and validation methods
  def generate_authentication_tokens
    self.client = Devise.friendly_token
    self.access_token =  Devise.friendly_token
  end

  # Instance methods
  def access_token=(token)
    self.raw_access_token = token
    self.encrypted_access_token = Authentication.token_encryptor(token)
  end

  def access_token
    self.raw_access_token
  end

  # Class methods
  def self.token_compare(token, enc_token)
    Devise.secure_compare(token_encryptor(token), enc_token)
  end

  def self.token_encryptor(token)
    Devise.token_generator.digest(Authentication, :encrypted_access_token, token)
  end
end
