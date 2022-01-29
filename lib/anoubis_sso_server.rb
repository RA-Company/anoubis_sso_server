require_relative "anoubis_sso_server/version"
require_relative "anoubis_sso_server/engine"

## Main module of library for create basic SSO Server based on OAUTH authentication.
module AnoubisSsoServer
  ## Default error class
  class Error < StandardError;
  end
end
