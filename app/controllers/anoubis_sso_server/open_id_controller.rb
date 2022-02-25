##
# OpenID controller class. Defines any OpenID actions according by specification.
class AnoubisSsoServer::OpenIdController < AnoubisSsoServer::ApplicationController

  ##
  # Action returns {https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfigurationResponse Provider OpenID configuration}.
  #
  # Default path: /openid/.well-known/openid-configuration
  # @return [Hash] Current OpenID configuration
  def configuration
    result = {
      issuer: sso_server + 'openid/',
      authorization_endpoint: sso_server + 'openid/oauth2/auth',
      token_endpoint: sso_server + 'openid/oauth2/token',
      jwks_uri: sso_server + 'openid/.well-known/jwks.json',
      subject_types_supported: %w[public],
      #response_types_supported: ['code', 'code id_token', 'id_token', 'token id_token', 'token', 'token id_token code'],
      response_types_supported: %w[code],
      claims_supported: %w[sub],
      #grant_types_supported: ['authorization_code', 'implicit', 'client_credentials', 'refresh_token'],
      grant_types_supported: %w[authorization_code],
      response_modes_supported: %w[query fragment],
      userinfo_endpoint: sso_server + 'openid/userinfo',
      scopes_supported: %w[offline_access offline openid'],
      token_endpoint_auth_methods_supported: %w[client_secret_post client_secret_basic private_key_jwt none],
      userinfo_signing_alg_values_supported: %w[none RS256],
      id_token_signing_alg_values_supported: %w[RS256],
      request_parameter_supported: true,
      request_uri_parameter_supported: true,
      require_request_uri_registration: true,
      claims_parameter_supported: false,
      revocation_endpoint: sso_server + 'openid/oauth2/revoke',
      backchannel_logout_supported: true,
      backchannel_logout_session_supported: true,
      frontchannel_logout_supported: true,
      frontchannel_logout_session_supported: true,
      end_session_endpoint: sso_server + 'openid/oauth2/sessions/logout',
      request_object_signing_alg_values_supported: %w[RS256 none],
      code_challenge_methods_supported: %w[plain S256]
    }

    render json: result
  end

  ##
  # Action returns OpenID JWKs.
  #
  # Default path: /openid/.well-known/jwks.json
  # @return [Hash] Current JWKs
  def jwks
    begin
      jwks_cache = JSON.parse(self.redis.get("#{redis_prefix}jwks"),{ symbolize_names: true })
    rescue StandardError => e
      jwks_cache = generate_jwks
    end

    redis.set "#{redis_prefix}jwks", jwks_cache.to_json, ex: 3600

    render json: jwks_cache
  end

  ##
  # Action for check user authorization for current browser.
  def auth
    result = {
      result: -1
    }

    params[:prompt] = 'is' unless params.key? :prompt
    params[:prompt] = 'is' if params[:prompt] != 'none'

    err = check_basic_parameters

    if err
      result[:message] = err
      return render(json: result)
    end

    sign = params[:redirect_uri].index('?') ? '&' : '?'

    err = check_listed_parameters %w[response_type scope code_challenge code_challenge_method state]

    if err
      result[:message] = err
      return if redirect_to_uri result[:message], sign
      return render(json: result)
    end

    unless %w[code].include? params[:response_type]
      result[:message] = I18n.t('anoubis.errors.is_not_correct', title: 'response_type')
      return if redirect_to_uri result[:message], sign
      return render(json: result)
    end

    scopes = params[:scope].split(' ')

    params[:code_challenge_method] = params[:code_challenge_method].downcase
    unless %w[s256].include? params[:code_challenge_method]
      result[:message] = I18n.t('anoubis.errors.is_not_correct', title: 'code_challenge_method')
      return if self.redirect_to_uri result[:message], sign
      return render(json: result)
    end

    if params[:state].length < 6
      result[:message] = I18n.t('anoubis.errors.less_than', title: 'state', size: 6)
      return if self.redirect_to_uri result[:message], sign
      return render(json: result)
    end

    logged_in = false

    original_url = request.url[8..]
    original_url = original_url[(original_url.index('/') + 1)..]

    code = SecureRandom.uuid
    code_hash = {
      scope: scopes,
      code_challenge: params[:code_challenge],
      request_uri: params[:redirect_uri],
      state: params[:state],
      client_id: params[:client_id],
      original_url: sso_server + original_url
    }

    puts 'Auth'
    puts code_hash
    session = self.get_oauth_session

    puts 'Session'
    puts session

    result[:mesasge] = I18n.t('anoubis.errors.login_required')

    if params[:prompt] == 'none'
      redirect_to "#{params[:redirect_uri]}#{sign}error=#{result[:message]}", { allow_other_host: true }
      return
    end

    url = sso_login_url
    url += url.index('?') ? '&' : '?'
    redis.set("#{redis_prefix}login_code:#{code}", code_hash.to_json, ex: 3600)
    redirect_to "#{url}code=#{code}", { allow_other_host: true }
  end


  ##
  # Check basic oauth parameters (client_id, redirect_uri)
  def check_basic_parameters
    return I18n.t('anoubis.errors.is_not_defined', title: 'client_id') unless params.key? :client_id

    @current_system = self.get_current_system params[:client_id]

    return I18n.t('anoubis.errors.is_not_correct', title: 'client_id') unless current_system

    return I18n.t('anoubis.errors.is_not_defined', title: 'redirect_uri') unless params.key? :redirect_uri

    return I18n.t('anoubis.errors.is_not_correct', title: 'redirect_uri') unless current_system.request_uri.include? params[:redirect_uri]

    nil
  end

  ##
  # Check parameters
  # @param list [Array] Array of parameters to check
  def check_listed_parameters(list)
    list.each do |key|
      return I18n.t('anoubis.errors.is_not_defined', title: key) unless params.key? key.to_sym

      return I18n.t('anoubis.errors.is_not_correct', title: key) unless params[key.to_sym]

      params[key.to_sym].strip!

      return I18n.t('anoubis.errors.is_not_correct', title: key)  if params[key.to_sym] == ''
    end

    nil
  end

  ##
  # Check if page should be redirected to url
  # @param error [String] Error message
  # @param sign [String] Redirect url sign (? or &)
  # @return [Boolean] return 'true' if page should be redirected
  def redirect_to_uri(error, sign)
    puts 'redirect_to_uri(error, sign)'
    puts error, sign
    if params[:prompt] == 'none'
      redirect_to params[:redirect_uri] + sign + 'error=' + ERB::Util.url_encode(error), { allow_other_host: true }
      return true
    end

    false
  end

  ##
  # Procedure generates keys according by used systems. Data is loaded from {AnoubisSsoServer::System}.
  # @return [Hash] Hash ow JWK keys
  def generate_jwks
    result = {
      keys: []
    }

    AnoubisSsoServer::System.where(state: 'opened').each do |sys|
      key = {
        use: 'sig',
        kty: sys.jwk[:kty],
        kid: "public:#{sys.uuid}",
        alg: 'RS256',
        n: sys.jwk[:n],
        e: sys.jwk[:e]
      }
      result[:keys].push key
    end

    result
  end
end