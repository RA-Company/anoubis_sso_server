##
# Main application class inherited from {https://www.rubydoc.info/gems/anoubis/Anoubis/ApplicationController Anoubis::ApplicationController}
class AnoubisSsoServer::ApplicationController < Anoubis::ApplicationController
  ## Selected SSO system
  attr_accessor :current_system

  ## Returns main SSO server URL.
  attr_accessor :sso_server

  ## Returns SSO Login URL used for redirect when user isn't logged in.
  attr_accessor :sso_login_url

  ## Returns SSO silent url used for silent refresh token.
  attr_accessor :sso_silent_url

  ## Returns used User model
  attr_accessor :user_model

  ##
  # Returns main SSO server URL. Link should be defined in Rails.configuration.anoubis.sso_server configuration parameter
  # @return [String] link to SSO server
  def sso_server
    @sso_server ||= get_sso_server
  end

  private def get_sso_server
    begin
      value = Rails.configuration.anoubis_sso_server
    rescue StandardError
      value = ''
      render json: { error: 'Please setup Rails.configuration.anoubis_sso_server configuration variable' }
    end

    value
  end

  ##
  # Returns SSO Login URL used for redirect when user isn't logged in.
  # Link can be redefined in Rails.configuration.anoubis_sso_login_url configuration parameter. If this variable isn't defined
  # URL wil be defined as {sso_server}login
  # @return [String] SSO login URL
  def sso_login_url
    @sso_login_url ||= get_sso_login_url
  end

  private def get_sso_login_url
    begin
      value = Rails.configuration.anoubis_sso_login_url
    rescue
      value = sso_server + 'login'
    end

    value
  end

  ##
  # Returns SSO silent url used for silent refresh token.
  # Link can be redefined in Rails.configuration.anoubis_sso_silent_url configuration parameter. If this variable isn't defined
  # URL wil be defined as {sso_server}silent.html
  # @return [String] SSO login URL
  def sso_silent_url
    @sso_silent_url ||= get_sso_silent_url
  end

  private def get_sso_silent_url
    begin
      value = Rails.configuration.anoubis_sso_silent_url
    rescue
      value = sso_server + 'silent.html'
    end

    value
  end

  ##
  # Returns SSO User model.
  # Can be redefined in Rails.application configuration_anoubis_ss_user_model configuration parameter.
  # By default returns {AnoubisSsoServer::User} model class
  # @return [Class] User model class
  def user_model
    @user_model ||= get_user_model
  end

  private def get_user_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_user_model
    rescue
      value = AnoubisSsoServer::User
    end

    value
  end

  ##
  # Check current origin of header by Regexp defined in Rails.configuration.anoubis_sso_origin configuration parameter
  # @return [Boolean] request host origin validation
  def check_origin
    request.headers['origin'].match(Rails.configuration.anoubis_sso_origin)
  end

  ##
  # Return OAUTH session for current request. Session name gets from cookies. If session present but it's timeout was expired, then session regenerated.
  def get_oauth_session
    if cookies.key? :oauth_session
      begin
        session = JSON.parse(self.redis.get("#{redis_prefix}session:#{cookies[:oauth_session]}"),{ symbolize_names: true })
      rescue
        cookies[:oauth_session] = nil
        session = nil
      end
    end

    if session
      if session[:ttl] < Time.now.utc.to_i
        session_name = SecureRandom.uuid
        session[:ttl] = Time.now.utc.to_i + session[:timeout]
        redis.del("#{redis_prefix}session:#{cookies[:oauth_session]}")
        cookies[:oauth_session] = session_name
        redis.set("#{redis_prefix}session:#{session_name}", session.to_json, { ex: 86400 })
      end
    end

    session
  end

  ##
  # Returns user by UUID from the Redis cache or from database. If User isn't present in cache than User is loaded from database and placed to cache.
  # @param uuid [String] UUID of user
  # @return [Class] Returns user class
  def get_user_by_uuid(uuid)
    begin
      user = user_model.new JSON.parse(redis.get("#{redis_prefix}user:#{uuid}"),{ symbolize_names: true })
    rescue
      user = nil
    end

    return user if user

    user = user_model.where(uuid: uuid).first
    return nil unless user

    redis.set("#{redis_prefix}user:#{uuid}", user.to_json(except: :password_digest))

    user
  end
end