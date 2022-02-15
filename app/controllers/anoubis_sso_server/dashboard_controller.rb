##
# Dashboard controller class. Output summary information
class AnoubisSsoServer::DashboardController < AnoubisSsoServer::ApplicationController

  ##
  # Default dashboard action
  def index
    result = {
      result: 0,
      message: I18n.t('anoubis.success'),
      data: {
        name: current_user.name,
        surname: current_user.surname,
        email: current_user.email,
        id: current_user.public
      }
    }

    render json: result
  end

  def authenticate?
    true
  end
end