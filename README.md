# AnoubisSsoServer

Gem for create simple SSO server, based on OAUTH2 authentication.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'anoubis_sso_server'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install anoubis_sso_server

After it please install default migrations:

    $ rails anoubis_sso_server:install:migrations
    $ bundle exec rake db:migrate

## Usage

By default system database isn't filled any data.

For adding data to database please add this to db/seed.rb of your application.

First of all add admin user to database:

```ruby
user = AnoubisSsoServer::User.where(email: '<your_email>').first
unless user
  user = AnoubisSsoServer::User.new
  user.email = '<your_email>'
  user.password = '<your_password>'
  user.password_confirmation = '<your_password>'
  user.name = '<your_name>'
  user.surname = '<your_surname>'
  user.save
end
```

Please use strong password when create user login.

Then add systems to database.

```ruby
system = AnoubisSsoServer::System.where(public: 'sso-system').first
unless system
  system = AnoubisSsoServer::System.new
  system.title = 'SSO'
  system.public = 'sso-system'
  system.state = 'hidden'
  system.save
end

ext_system = AnoubisSsoServer::System.where(public: '<system_identifier>').first
unless ext_system
  ext_system = AnoubisSsoServer::System.new
  ext_system.title = '<system_name>'
  ext_system.public = '<system_identifier>'
  ext_system.request_uri = %w[https://<server_url>/silent-callback.html https://<server_url>/callback]
  ext_system.save
end
```

After this seed this data to database:

    $ bundle exec rake db:seed

## Configuration parameters

This configuration parameters can be placed at files config/application.rb for global configuration or config/environments/<environment>.rb for custom environment configuration.

```ruby
config.anoubis_redis_prefix = '<sample-prefix>' # Redis prefix for store cache data (when many applications run in one physical server)
config.anoubis_sso_server = 'https://sso.example.com/' # Full URL of SSO server (*required)
config.anoubis_sso_system = 'sso-system' # Internal SSO system identifier (*required)
config.anoubis_sso_origin = /^https:\/\/.*\.example\.com$/ # Regexp for prevent CORS access from others domain (*required)
config.anoubis_sso_login_url = 'https://sso.example.com/login' # Full URL for login page. (By default calculate from config.anoubis_sso_server adding 'login') (*optional)
config.anoubis_sso_silent_url = 'https://sso.example.com/silent.html' # Full URL for silent refresh page. (By default calculate from config.anoubis_sso_server adding 'silent.html') (*optional)
config.anoubis_sso_user_model = 'AnoubisSsoServer::User'# Used user model. ()By default used AnoubisSsoServer::User model) (*optional)
```

Also pay attention on this configuration parameters:

```ruby
config.api_only = true # for API only application
config.middleware.use ActionDispatch::Cookies # for attach cookies into the API application

config.hosts.clear # for clearing allowed IP requests

config.action_dispatch.default_headers.clear # for clear default response headers 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

First of all create MySQL database and grant privileges to it.

After that copy file `.env.sample` to `.env` and fill required fields like `DATABASE_NAME`, `DATABASE_USER` and `DATABASE_PASSWORD`.

After it run migrate database to test environment:

    $ bin/rails db:migrate RAILS_ENV=test DATABASE_USER=<user_name> DATABASE_PASSWORD=<user_password> DATABASE_NAME=<database_name>

After all of this preparation you can start tests:

    $ bundle exec rspec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RA-Company/anoubis_sso_server. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/RA-Company/anoubis_sso_server/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AnoubisSsoServer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/RA-Company/anoubis_sso_server/blob/master/CODE_OF_CONDUCT.md).
