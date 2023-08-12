# Changelog

## [3.0.0](https://github.com/craigulliott/dynamic_migrations/compare/v2.2.0...v3.0.0) (2023-08-11)


### ⚠ BREAKING CHANGES

* functions and triggers, removed unusable index_type from primary key and unique constraints, added active record migrations and some general refactoring

### Features

* adding migration generators and active record migrators ([80bf481](https://github.com/craigulliott/dynamic_migrations/commit/80bf481bfd33941b8380e7deb010b171898c03df))
* functions and triggers, removed unusable index_type from primary key and unique constraints, added active record migrations and some general refactoring ([45fcb7c](https://github.com/craigulliott/dynamic_migrations/commit/45fcb7ca3b6724625a4868198a9e75aefb1ea964))
* now generating migrations from all database structure object types ([871ab04](https://github.com/craigulliott/dynamic_migrations/commit/871ab048efb6247bc7fadb6e49bb15f6933c5586))
* various improvements to triggers and functions, and other general improvements ([e7dd9ab](https://github.com/craigulliott/dynamic_migrations/commit/e7dd9abeee736ea2791c192d3f797497f54773b4))
* work in progress on the migrations generator ([3e8deb9](https://github.com/craigulliott/dynamic_migrations/commit/3e8deb954913be291ad8e6e7d1c09af619378e4d))
* work in progress on the migrations generator ([7a999ee](https://github.com/craigulliott/dynamic_migrations/commit/7a999ee8467527164e79f2c6da704245e78cf0cd))

## [2.2.0](https://github.com/craigulliott/dynamic_migrations/compare/v2.1.0...v2.2.0) (2023-07-31)


### Features

* using postgres shorthand names such as `numeric(12,2)` for types, and removing the additional column metadata ([86d0113](https://github.com/craigulliott/dynamic_migrations/commit/86d0113aabd4350f278164d18e3c0a611fcf5595))

## [2.1.0](https://github.com/craigulliott/dynamic_migrations/compare/v2.0.0...v2.1.0) (2023-07-31)


### Features

* apply default column values to column data types ([6911c5f](https://github.com/craigulliott/dynamic_migrations/commit/6911c5f2026b47ef2e9f7bc529f7ff0d8f098700))

## [2.0.0](https://github.com/craigulliott/dynamic_migrations/compare/v1.1.1...v2.0.0) (2023-07-27)


### ⚠ BREAKING CHANGES

* changing all name related methods from %object%_name to just name (i.e. `table.table_name` is now just `table.name`)

### Features

* changing all name related methods from %object%_name to just name (i.e. `table.table_name` is now just `table.name`) ([77f18ae](https://github.com/craigulliott/dynamic_migrations/commit/77f18ae168c2449fa437fa7692ff9339931f9076))

## [1.1.1](https://github.com/craigulliott/dynamic_migrations/compare/v1.1.0...v1.1.1) (2023-07-17)


### Bug Fixes

* validating that new databases don't already exist and removing a debug print statement ([73bed2d](https://github.com/craigulliott/dynamic_migrations/commit/73bed2d6ab928c7a8f53b2aa17a188a77ed369e9))
* validating that new databases don't already exist and removing a debug print statement ([73bed2d](https://github.com/craigulliott/dynamic_migrations/commit/73bed2d6ab928c7a8f53b2aa17a188a77ed369e9))
* validating that new databases don't already exist and removing a debug print statement ([f4cfb1e](https://github.com/craigulliott/dynamic_migrations/commit/f4cfb1e81252ed967ad1a6d864d495c182ca908f))

## [1.1.0](https://github.com/craigulliott/dynamic_migrations/compare/v1.0.0...v1.1.0) (2023-07-10)


### Features

* storing and returning database structure objects in alphabetical order of their names ([1b3255b](https://github.com/craigulliott/dynamic_migrations/commit/1b3255b220349bfb63d7f72d990557a104131cf7))

## 1.0.0 (2023-07-05)


### Features

* added table and column comments and column metadata ([84d798a](https://github.com/craigulliott/dynamic_migrations/commit/84d798aae35c259545f73dbbd7d076d8ceaa8739))
* basic representation of schema either configured or loaded from a real database ([7fc9ebb](https://github.com/craigulliott/dynamic_migrations/commit/7fc9ebbe5a8e5faa4e6017deec9bc66f7ba15f16))
* recursively load and builds a representation of current database schema, and find differences between configured and loaded representations of the database structure ([978e122](https://github.com/craigulliott/dynamic_migrations/commit/978e12279760709f1511dc7c6d9fe7ff57b54f3e))
* renaming the current version of constraints to validations, because its a more descriptive name, especially when considering we are going to expose multiple types of postgres constraint ([2f17af6](https://github.com/craigulliott/dynamic_migrations/commit/2f17af665028ed6f49d8bdd9b7ff6a52339206db))
* support for table constraints and added caches for database structure and constraints ([f68bbb2](https://github.com/craigulliott/dynamic_migrations/commit/f68bbb20a25fab149ed4b3b9c591fde1a6ff628e))
* table keys and indexes and a more robust database configured/loaded comparison class ([b4a0925](https://github.com/craigulliott/dynamic_migrations/commit/b4a092535e4e59d0fb9b97efc3d210289346b454))
