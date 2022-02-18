##
# Main controller class. Defines basic internal SSO actions.
class AnoubisSsoServer::MainController < AnoubisSsoServer::ApplicationController
  ##
  # Login action for SSO server.
  #
  # <b>API request:</b>
  #   GET /api/<version>/login
  #
  # <b>Parameters:</b>
  # - <b>login</b> (String) --- user email address <i>(required field)</i>
  # - <b>password</b> (String) --- user password <i>(required field)</i>
  # - <b>locale</b> (String) --- the output language locale <i>(optional value)</i>
  # - <b>code</b> (String) --- login code for redirect <i>(optional value, default: 0)</i>
  #
  # <b>Request example:</b>
  #   curl --header "Content-Type: application/json" http://<server>:<port>/api/<api-version>/login=admin@example.com&password=password&locale=en
  #
  # <b>Results:</b>
  #
  # Resulting data returns as redirect to silent URL with login result.

  def login
    redirect_url = sso_silent_url
    redirect_url += redirect_url.index('?') ? '&' : '?'

    unless params[:login]
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.fields.login')), { allow_other_host: true }
      return
    end

    unless params[:password]
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.fields.password')), { allow_other_host: true }
      return
    end

    usr = user_model.where(email: params[:login]).first

    unless usr
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.incorrect_login')), { allow_other_host: true }
      return
    end

    unless usr.authenticate(params[:password])
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.incorrect_login')), { allow_other_host: true }
      return
    end

    self.current_system = get_current_system

    unless current_system
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.system_not_defined')), { allow_other_host: true }
      return
    end

    code = nil
    if params[:code]
      begin
        code = JSON.parse(self.redis.get("#{self.redis_prefix}login_code:#{params[:code]}"),{ symbolize_names: true })
      rescue

      end
    end

    session_name = SecureRandom.uuid
    session = {
      id: usr.id,
      uuid: usr.uuid,
      ttl: Time.now.utc.to_i + current_system[:ttl],
      timeout: current_system[:ttl]
    }

    cookies[:oauth_session] = session_name
    redis.set("#{redis_prefix}session:#{session_name}", session.to_json, ex: 86400)

    unless code
      redirect_to redirect_url + "code=0", { allow_other_host: true }
    else
      auth_code = SecureRandom.uuid
      redis.set("#{redis_prefix}auth_code:#{auth_code}", params[:code], ex: 600)
      redirect_to redirect_url + "code=#{auth_code}", { allow_other_host: true }
    end
  end
end