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

  ## Used sso_origin
  attr_accessor :sso_origin

  ##  Returns [Anoubis::Etc::Base] global system parameters
  attr_accessor :etc

  ##
  # Current user
  attr_accessor :current_user

  ##
  # Action fires before any other actions
  def after_anoubis_initialization
    if defined? params
      self.etc = Anoubis::Etc::Base.new({ params: params })
    else
      self.etc = Anoubis::Etc::Base.new
    end

    if access_allowed?
      options request.method.to_s.upcase
    else
      render_error_exit({ error: I18n.t('errors.access_not_allowed') })
      return
    end

    if self.authenticate?
      if self.authentication
        if self.check_menu_access?
          return if !self.menu_access params[:controller]
        end
      end
    end

    puts etc.inspect
  end

  ##
  # Check for site access. By default return true.
  def access_allowed?
    true
  end

  ##
  # Checks if needed user authentication.
  # @return [Boolean] if true, then user must be authenticated. By default application do not need authorization.
  def authenticate?
    false
  end


  ##
  # Procedure authenticates user in the system
  def authentication
    session = get_oauth_session

    unless session
      render_error_exit code: -2, error: I18n.t('anoubis.errors.session_expired')
      return
    end

    self.current_user = get_user_by_uuid session[:uuid]

    unless current_user
      self.redis.del("#{redis_prefix}session:#{cookies[:oauth_session]}")
      cookies[:oauth_session] = nil
      render_error_exit code: -3, error: I18n.t('anoubis.errors.incorrect_user')
      return
    end
  end

  ##
  # Gracefully terminate script execution with code 422 (Unprocessable entity). And JSON data
  # @param data [Hash] Resulting data
  # @option data [Integer] :code resulting error code
  # @option data [String] :error resulting error message
  def render_error_exit(data = {})
    result = {
      result: -1,
      message: I18n.t('anoubis.error')
    }

    result[:result] = data[:code] if data.has_key? :code
    result[:message] = data[:error] if data.has_key? :error


    render json: result, status: :unprocessable_entity

    begin
      exit
    rescue SystemExit => e
      puts result[:message]
    end
  end

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
  # Returns SSO origin. Variable should be defined in Rails.configuration.anoubis.sso_origin configuration parameter
  # @return [Regexp] regexp for check site origin
  def sso_origin
    @sso_origin ||= get_sso_origin
  end

  private def get_sso_origin
    begin
      value = Rails.configuration.anoubis_sso_origin
    rescue StandardError
      value = /^.*$/
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
  # Can be redefined in Rails.application configuration_anoubis_sso_user_model configuration parameter.
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
  # Returns current SSO system data
  # @param system_title [String] - System public UUID parameter. By default load from Rails.application configuration_anoubis_sso_system configuration parameter.
  # @return [AnoubisSsoServer::System] current SSO system
  def get_current_system(system_title = nil)
    begin
      system_title = Rails.configuration.anoubis_sso_system unless system_title
      system = AnoubisSsoServer::System.new(JSON.parse(redis.get("#{redis_prefix}system:#{system_title}"),{ symbolize_names: true }))
    rescue
      system = nil
    end

    system
  end

  ##
  # Check current origin of header by Regexp defined in Rails.configuration.anoubis_sso_origin configuration parameter
  # @return [Boolean] request host origin validation
  def check_origin
    puts 'check_origin'
    puts request.inspect
    puts headers.inspect
    puts request.origin
    puts headers['origin']
    false
    #headers['origin'].match(sso_origin)
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
        redis.set("#{redis_prefix}session:#{session_name}", session.to_json, ex: 86400)
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