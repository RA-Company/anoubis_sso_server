##
# Default user class
class AnoubisSsoServer::User < AnoubisSsoServer::ApplicationRecord
  self.table_name = 'users'

  has_secure_password
  validates :email, presence: true

  before_validation :before_validation_sso_server_user_on_create, on: :create
  before_save :before_save_sso_server_user
  after_destroy :after_destroy_sso_server_user

  ## Regexp validation mask for email
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :email, presence: true, length: { maximum: 50 },
            format: { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: true }

  validates :name, presence: true, length: { maximum: 100 }
  validates :surname, presence: true, length: { maximum: 100 }

  validates :password, length: { in: 5..30 }, on: [:create]
  validates :password, length: { in: 5..30 }, on: [:update], if: :password_changed?
  validates :password_confirmation, length: { in: 5..30 }, on: [:create]
  validates :password_confirmation, length: { in: 5..30 }, on: [:update], if: :password_changed?

  validates :uuid, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }
  validates :public, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }

  ##
  # Fires before create any User on the server. Procedure generates internal UUID, public UUID and setup timezone to GMT.
  def before_validation_sso_server_user_on_create
    self.uuid = SecureRandom.uuid
    self.public = SecureRandom.uuid
    self.timezone = 'GMT' if !self.timezone
  end

  ##
  # Fires before save User data to database.
  # Procedure setup email, timezone and call procedure for clear Redis cache data for the user.
  def before_save_sso_server_user
    self.timezone = 'GMT' if !self.timezone
    self.email = self.email.downcase
    self.clear_cache
  end

  ##
  # Fires before delete User from database.
  # Procedure call procedure for clear Redis cache data for the user.
  def after_destroy_sso_server_user
    self.clear_cache
  end

  ##
  # Procedure saves cached User model data to Redis database for improve access speed.
  def save_cache
    self.redis.set("#{redis_prefix}user:#{uuid}", self.to_json(except: [:password_digest])) if self.redis
  end

  ##
  # Procedure clear cached User model data.
  def clear_cache
    self.redis.del("#{redis_prefix}user:#{uuid}") if self.redis
  end

  ##
  # Procedure checks if password was changed.
  # @return [Boolean] return true if password was changed
  def password_changed?
    !password.blank?
  end

  ##
  # Procedure returns User model data from the cache or database. If user data isn't present in cache then call procedure that cache User model data.
  # @param uuid [String] - User private UUID
  # @return [Hash] User data
  def self.load_cache(uuid)
    begin
      data = JSON.parse self.redis.get("#{self.redis_prefix}user:#{uuid}"), { symbolize_names: true }
    rescue
      data = nil
    end

    unless data
      user = self.where(uuid: uuid).first

      return nil unless user

      user.save_cache
      data = JSON.parse(user.to_json(except: [:password_digest]), { symbolize_names: true })
    end

    data
  end
end
