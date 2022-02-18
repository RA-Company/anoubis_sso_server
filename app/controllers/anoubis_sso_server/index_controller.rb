##
# Index controller class. Output system actions
class AnoubisSsoServer::IndexController < AnoubisSsoServer::ApplicationController

  ##
  # Default dashboard action
  def dashboard
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

  ##
  # Output allowed menu items
  def menu
    result = {
      result: 0,
      message: I18n.t('anoubis.success'),
      menu: [
        {
          mode: 'dashboard',
          title: I18n.t('anoubis.install.menu.dashboard.title'),
          page_title: I18n.t('anoubis.install.menu.dashboard.page_title'),
          short_title: I18n.t('anoubis.install.menu.dashboard.short_title'),
          position: 0,
          tab: 0,
          action: 'data',
          access: 'write',
          state: 'show',
          parent: nil
        }
      ]
    }

    render json: result
  end

  def authenticate?
    true
  end
end