module AnoubisSsoServer
  ##
  # Main AnubisSsoServer Engine class
  class Engine < ::Rails::Engine
    isolate_namespace AnoubisSsoServer
    config.generators.api_only = true

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
    end
  end
end
