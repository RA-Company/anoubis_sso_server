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
    jwks_cache_name = "#{redis_prefix}jwks"

    begin
      jwks_cache = JSON.parse(self.redis.get(jwks_cache_name),{ symbolize_names: true })
    rescue StandardError => e
      jwks_cache = {}
      jwks_cache[:time] = Time.now.utc.to_i + 3600
      jwks_cache[:data] = generate_jwks
    end

    jwks_cache[:data] = generate_jwks if jwks_cache[:time] < Time.now.utc.to_i

    jwks_cache[:time] = Time.now.utc.to_i + 3600
    redis.set jwks_cache_name, jwks_cache.to_json

    render json: jwks_cache[:data]
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
        kid: "public:#{sys.public}",
        alg: 'RS256',
        n: sys.jwk[:n],
        e: sys.jwk[:e]
      }
      result[:keys].push key
    end

    result
  end
end