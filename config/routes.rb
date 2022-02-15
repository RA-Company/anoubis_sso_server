##
# Defines default routes
AnoubisSsoServer::Engine.routes.draw do
  Rails.application.routes.draw do
    scope path: 'api', defaults: { format: 'json' } do
      scope path: ':version' do
        get 'login', to: 'anoubis_sso_server/main#login', as: 'api_internal_login'
        #get 'auth', to: 'main#auth'
        get 'dashboard', to: 'anoubis_sso_server/dashboard#index'
      end
    end

    scope path: 'openid', defaults: { format: 'json' } do
      get '.well-known/openid-configuration', to: 'anoubis_sso_server/open_id#configuration', as: 'openid_configuration'
      get '.well-known/jwks.json', to: 'anoubis_sso_server/open_id#jwks', as: 'openid_jwks'
    end
  end
end