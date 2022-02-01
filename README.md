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

After this seed this data to database:

    $ bundle exec rake db:seed

## Configuration parameters

This configuration parameters can be placed at files config/application.rb for global configuration or config/environments/<environment>.rb for custom environment configuration.

```ruby
config.anoubis_sso_server = 'https://sso.example.com/' # Full URL of SSO server
config.anoubis_sso_login_url = 'https://sso.example.com/login' # Full URL for login page. (By default calculate from config.anoubis_sso_server adding 'login')
config.anoubis_sso_silent_url = 'https://sso.example.com/silent.html' # Full URL for silent refresh page. (By default calculate from config.anoubis_sso_server adding 'silent.html')
config.anoubis_sso_origin = /^https:\/\/.*\.example\.com$/ # Regexp for prevent CORS access from others domain
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RA-Company/anoubis_sso_server. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/RA-Company/anoubis_sso_server/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AnoubisSsoServer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/RA-Company/anoubis_sso_server/blob/master/CODE_OF_CONDUCT.md).
