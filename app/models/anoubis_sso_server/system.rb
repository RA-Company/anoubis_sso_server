##
# Default System class
class AnoubisSsoServer::System < AnoubisSsoServer::ApplicationRecord
  self.table_name = 'systems'

  before_validation :before_validation_sso_server_system_on_create, on: :create
  before_save :before_save_sso_server_system
  after_save :after_save_sso_server_system
  after_destroy :after_destroy_sso_server_system

  validates :title, presence: true, length: { maximum: 100 }
  validates :uuid, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }
  validates :public, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }

  enum state: { opened: 0, hidden: 1 }

  ##
  # Fires before create system. Procedure generates public and private UUID and RSA keypair
  def before_validation_sso_server_system_on_create
    self.uuid = setup_private_system_id
    self.public = setup_public_system_id unless public
    self.request_uri = [] unless request_uri

    keys = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))
    self.jwk = keys.export include_private: true
  end

  ##
  # Procedure setup private user identifier. Procedure can be redefined.
  # @return [String] public user identifier
  def setup_private_system_id
    SecureRandom.uuid
  end

  ##
  # Procedure setup public user identifier. Used for open API. Procedure can be redefined.
  # @return [String] public user identifier
  def setup_public_system_id
    SecureRandom.uuid
  end

  ##
  # Returns JWK information
  # @return [Hash] JWK information
  def jwk
    @jwk ||= super.deep_symbolize_keys!
  end

  ##
  # Fires before System was saved to SQL database. Delete old system cache if public identifier was changed.
  def before_save_sso_server_system
    redis.del "#{redis_prefix}system:#{public_was}" if public_was && public != public_was
  end

  ##
  # Fires after System was saved to SQL database and setup system cache in Redis database for fast access.
  def after_save_sso_server_system
    redis.set("#{redis_prefix}system:#{public}", { uuid: uuid, public: public, request_uri: request_uri, jwk: jwk, ttl: ttl }.to_json )
    redis.del "#{redis_prefix}jwks"
  end

  ##
  # Fires after System was destroyed. Clears all systems caches.
  def after_destroy_sso_server_system
    redis.del "#{redis_prefix}system:#{public}"
    redis.del "#{redis_prefix}jwks"
  end
end
