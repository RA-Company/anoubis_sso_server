class AnoubisSsoServer::User < ApplicationRecord
  self.table_name = 'users'

  has_secure_password
  validates :email, presence: true

  before_validation :before_validation_user_on_create, on: :create
  before_save :before_save_user
  after_destroy :after_destroy_user

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

  def before_validation_user_on_create
    self.uuid = SecureRandom.uuid
    self.public = SecureRandom.uuid
    self.timezone = 'GMT' if !self.timezone
  end

  def before_save_user
    self.timezone = 'GMT' if !self.timezone
    self.email = self.email.downcase
    self.clear_cache
  end

  def after_destroy_user
    self.clear_cache
  end

  def save_cache
    self.redis.set(self.redis_prefix + 'user:' + self.uuid, self.to_json(except: [:password_digest])) if self.redis
  end

  def clear_cache
    self.redis.del(self.redis_prefix + 'user:' + self.uuid) if self.redis
  end

  def password_changed?
    !password.blank?
  end

  def self.load_cache(redis, uuid)
    begin
      data = JSON.parse redis.get(User.redis_prefix + 'user:' + uuid), { symbolize_names: true }
    rescue
      data = nil
    end

    unless data
      user = self.where(uuid: uuid).first
      if user
        return JSON.parse(user.to_json(except: [:password_digest]), { symbolize_names: true })
      end
    end

    data
  end
end
