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
  # - <b>locale</b> (String) --- the output language locale <i>(optional value)</i>
  # - <b>offset</b> (String) --- starting number for selection <i>(optional value, default: 0)</i>
  # - <b>limit</b> (String) --- number of selected rows <i>(optional value, default: 10)</i>
  # - <b>tab</b> (String) --- the tab, is used for selected data <i>(optional value, default: first defined tab)</i>
  #
  # <b>Request example:</b>
  #   curl --header "Content-Type: application/json" --header 'Authorization: Bearer <session-token>' http://<server>:<port>/api/<api-version>/<controller>?offset=0&limit=10
  #
  # <b>Results:</b>
  #
  # Resulting data returns in JSON format.
  #
  # <b>Examples:</b>
  #
  # <b>Success:</b> HTTP response code 200
  #   {
  #     "result": 0,
  #     "message": "Successful",
  #     "count": 5,
  #     "tab": "inner",
  #     "offset": "0",
  #     "limit": "10",
  #     "timestamp": 1563169525,
  #     "fields": [
  #         {
  #             "prop": "title",
  #             "title": "Soldier Ttitle"
  #             "type": "string",
  #             "sortable": true
  #         },
  #         {
  #             "prop": "name",
  #             "title": "Soldier Name"
  #             "type": "string",
  #             "sortable": true
  #         },
  #         {
  #             "prop": "age",
  #             "title": "Girl Age"
  #             "type": "string",
  #             "sortable": true
  #         }
  #     ],
  #     "data": [
  #         {
  #             "id": 1,
  #             "sys_title": "Sailor Moon",
  #             "actions": {
  #                 "edit": "Edit: Sailor Moon",
  #                 "delete": "Delete: Sailor Moon"
  #             },
  #             "title": "Sailor Moon",
  #             "name": "Banny Tsukino",
  #             "age": 16,
  #             "state": "inner"
  #         },
  #         {
  #             "id": 2,
  #             "sys_title": "Sailor Mercury",
  #             "actions": {
  #                 "edit": "Edit: Sailor Mercury",
  #                 "delete": "Delete: Sailor Mercury"
  #             },
  #             "title": "Sailor Mercury",
  #             "name": "Amy Mitsuno",
  #             "age": 16,
  #             "state": "inner"
  #         }
  #     ]
  #   }

  def login
    redirect_url = sso_silent_url
    redirect_url += redirect_url.index('?') ? '&' : '?'

    result = {
      result: 0,
      message: I18n.t('anoubis.success')
    }

    unless params[:login]
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.fields.login')), { allow_other_host: true }
      return
    end

    unless params[:password]
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.fields.password')), { allow_other_host: true }
      return
    end

    u = user_model.where(email: params[:login]).first

    unless u
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.incorrect_login')), { allow_other_host: true }
      return
    end

    unless u.authenticate(params[:password])
      redirect_to redirect_url + 'error=' + ERB::Util.url_encode(I18n.t('anoubis.errors.incorrect_login')), { allow_other_host: true }
      return
    end

    code = nil
    if params[:code]
      begin
        code = JSON.parse(self.redis.get("#{self.redis_prefix}login_code:#{params[:code]}"),{ symbolize_names: true })
      rescue

      end
    end

    system = self.get_system Rails.configuration.sso_system

    session_name = SecureRandom.uuid
    session = {
      id: u.id,
      uuid: u.uuid,
      ttl: Time.now.utc.to_i + system[:ttl],
      timeout: system[:ttl]
    }

    cookies[:oauth_session] = session_name
    self.redis.set("#{self.redis_prefix}session:#{session_name}", session.to_json, { ex: 86400 })

    unless code
      redirect_to redirect_url + "code=0"
    else
      auth_code = SecureRandom.uuid
      self.redis.set("#{self.redis_prefix}auth_code:#{auth_code}", params[:code], { ex: 600 })
      redirect_to redirect_url + "code=#{auth_code}"
    end
  end
end