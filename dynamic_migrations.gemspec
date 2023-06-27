# frozen_string_literal: true

require_relative "lib/dynamic_migrations/version"

Gem::Specification.new do |spec|
  spec.name = "dynamic_migrations"
  spec.version = DynamicMigrations::VERSION
  spec.authors = ["Craig Ulliott"]
  spec.email = ["craigulliott@gmail.com"]

  spec.summary = "Manage your database schema through configuration"
  spec.description = "Monitor and generate database migrations based on difference between current schema and configuration"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["source_code_uri"] = "https://github.com/craigulliott/dynamic_migrations/"
  spec.metadata["changelog_uri"] = "https://github.com/craigulliott/dynamic_migrations/blob/main/CHANGELOG.md"

  spec.files = ["README.md", "LICENSE.txt", "CHANGELOG.md", "CODE_OF_CONDUCT.md"] + Dir["lib/**/*"]

  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 7.0"
  spec.add_dependency "activemodel", "~> 7.0"
  spec.add_dependency "activerecord", "~> 7.0"
end
