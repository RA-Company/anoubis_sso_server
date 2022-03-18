# frozen_string_literal: true

require_relative "lib/anoubis_sso_server/version"

Gem::Specification.new do |spec|
  spec.name = "anoubis_sso_server"
  spec.version = AnoubisSsoServer::VERSION
  spec.authors = ["Andrey Ryabov"]
  spec.email = ["andrey.ryabov@ra-company.kz"]

  spec.summary = "Library for create basic SSO Server based on OAUTH authentication."
  spec.description = "Library for create basic SSO Server based on OAUTH authentication."
  spec.homepage = "https://github.com/RA-Company/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/RA-Company/" + spec.name
  spec.metadata["changelog_uri"] = "https://github.com/RA-Company/" + spec.name + "/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/" + spec.name + "/" + spec.version.to_s

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "anoubis", "~> 1.0.1"
  spec.add_dependency "rails", "~> 7.0.0"
  spec.add_dependency "redis", "~> 4.5.1"
  spec.add_dependency "bcrypt", "~> 3.1.16"
  spec.add_dependency "rest-client", "~> 2.1.0"
  spec.add_dependency "mysql2", "~> 0.5.3"
  spec.add_dependency "jwt", "~> 2.3.0"

  spec.add_development_dependency "rake", "~> 0.13"
  spec.add_development_dependency "rspec", "~> 3.11.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2.0"
  spec.add_development_dependency "dotenv", '~> 2.7'
  spec.add_development_dependency "simplecov", '~> 0.21'
  spec.add_development_dependency "rubocop", '~> 1.25'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
