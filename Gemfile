# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in anoubis_sso_server.gemspec
gemspec

#gem "rake", "~> 13.0"
#gem "rspec", "~> 3.0"
#gem "rubocop", "~> 1.21"
gem 'redis'
gem 'jwt'
gem 'anoubis', git: 'https://github.com/RA-Company/anoubis.git', branch: 'main'

#group :development, :test do
#  gem "rspec-rails"
  #gem "factory_bot_rails"
#end

group :test do
  gem 'dotenv'
  gem 'dotenv-rails'
  gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
end