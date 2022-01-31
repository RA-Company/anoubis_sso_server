##
# Default System class
class AnoubisSsoServer::System < AnoubisSsoServer::ApplicationRecord
  before_validation :before_validation_sso_server_system_on_create, on: :create
  after_save :after_save_sso_server_system

  validates :title, presence: true, length: { maximum: 100 }
  validates :uuid, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }
  validates :public, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }

  enum state: { opened: 0, hidden: 1 }

  ##
  # Fires before create system. Procedure generates public and private UUID and RSA keypair
  def before_validation_sso_server_system_on_create
    self.uuid = SecureRandom.uuid
    self.public = SecureRandom.uuid
    self.request_uri = []

    keys = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))
    self.jwk = keys.export include_private: true
  end

  ##
  # Returns JWK information
  # @return [Hash] JWK information
  def jwk
    @jwk ||= super.deep_symbolize_keys!
  end

  ##
  # Fires after System was saved to SQL database and setup system cache in Redis database for fast access.
  def after_save_sso_server_system
    redis.set("#{redis_prefix}system:#{uuid}", { uuid: uuid, public: public, request_uri: request_uri, jwk: jwk, ttl: ttl }.to_json )
  end
end
