# DynamicMigrations

Monitor and generate database migrations based on difference between current schema and configuration.

[![Gem Version](https://badge.fury.io/rb/dynamic_migrations.svg)](https://badge.fury.io/rb/dynamic_migrations)
[![Specs](https://github.com/craigulliott/dynamic_migrations/actions/workflows/specs.yml/badge.svg)](https://github.com/craigulliott/dynamic_migrations/actions/workflows/specs.yml)
[![Types](https://github.com/craigulliott/dynamic_migrations/actions/workflows/types.yml/badge.svg)](https://github.com/craigulliott/dynamic_migrations/actions/workflows/types.yml)
[![Coding Style](https://github.com/craigulliott/dynamic_migrations/actions/workflows/linter.yml/badge.svg)](https://github.com/craigulliott/dynamic_migrations/actions/workflows/linter.yml)

## Key Features

* Supports complex validations via constraints
* Supports stored procedures
* Supports complex indexes and multi column foreign keys
* Supports postgis types
* Supports multiple postgres schemas
* Generates your database migrations
* Compares/validates actual database schema against desired configuration

## Installation

Install the gem by executing:

    $ gem install dynamic_migrations

Create your new platform:

    $ dynamic_migrations create my_platform_name

Note, this gem depends on the postgres gem `pg`, which depends on the `libpq` package. On Apple Silicon you can run the following commands before installation to prepare your system.

```
# required for pg gem on apple silicon
brew install libpq
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
``

## Getting Started

Todo


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

We use [Conventional Commit Messages](https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13).

Code should be linted and formatted according to [Ruby Standard](https://github.com/standardrb/standard).

Publishing is automated via github actions and Googles [Release Please](https://github.com/google-github-actions/release-please-action) github action

We prefer using squash-merges when merging pull requests because it helps keep a linear git history and allows more fine grained control of commit messages which get sent to release-please and ultimately show up in the changelog.

Type checking is enabled for this project. You can find the corresponding `rbs` files in the sig folder.

Install types for the packages used in development (such as `rspec`) by running

    $ rbs collection install

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/craigulliott/dynamic_migrations. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/craigulliott/dynamic_migrations/blob/master/CODE_OF_CONDUCT.md).

## License

This software is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DynamicMigrations project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/craigulliott/dynamic_migrations/blob/master/CODE_OF_CONDUCT.md).
