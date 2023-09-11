# Changelog

## [3.5.3](https://github.com/craigulliott/dynamic_migrations/compare/v3.5.2...v3.5.3) (2023-09-11)


### Bug Fixes

* accepting nil or false for existence check when calculating differences (because if the schema doesn't exist we wont have table objects to test against) ([de63879](https://github.com/craigulliott/dynamic_migrations/commit/de638791035a0a1ad4658149777aa6e2ac7dc2ed))

## [3.5.2](https://github.com/craigulliott/dynamic_migrations/compare/v3.5.1...v3.5.2) (2023-09-11)


### Bug Fixes

* accepting nil or false for existence check when calculating differences (because if the schema doesn't exist we wont have table objects to test against) ([c4112cc](https://github.com/craigulliott/dynamic_migrations/commit/c4112cccb5a887b78e15182cdb8bcfdbd80fd0c0))

## [3.5.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.5.0...v3.5.1) (2023-09-11)


### Bug Fixes

* missing primary key should be represented by nil when building differences, and added some more descriptive error messages ([491c1c2](https://github.com/craigulliott/dynamic_migrations/commit/491c1c2d7c2128f3f4ad3f2a21b0b52c67029185))

## [3.5.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.4.1...v3.5.0) (2023-09-11)


### Features

* adding rbs signatures to built gem so they are available in other projects ([03221b0](https://github.com/craigulliott/dynamic_migrations/commit/03221b0aa56acb9f1287f1d83c80570128793c7c))


### Bug Fixes

* fixing broken test around db extension migrations ([cdd6fab](https://github.com/craigulliott/dynamic_migrations/commit/cdd6fabaeecc6d5c51f744222eb5b81f5c2ff759))
* wrapping extension name in quotes, removing rogue semicolon from generated method name ([a6bdbd4](https://github.com/craigulliott/dynamic_migrations/commit/a6bdbd4710efdd07821425259be2a7cd609bc637))

## [3.4.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.4.0...v3.4.1) (2023-08-24)


### Bug Fixes

* validate that data type is a symbol ([f888f81](https://github.com/craigulliott/dynamic_migrations/commit/f888f819fdcd10772161f890024b937486c56c34))

## [3.4.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.3.1...v3.4.0) (2023-08-23)


### Features

* adding support for enums and extensions ([6e00d5f](https://github.com/craigulliott/dynamic_migrations/commit/6e00d5fc726e2a1bbeb282477c8bca92b94462cf))

## [3.3.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.3.0...v3.3.1) (2023-08-18)


### Bug Fixes

* automatically stripping whitespace from trigger parameters and conditions ([be229be](https://github.com/craigulliott/dynamic_migrations/commit/be229be3e3e6c416edfe4e4b0946fda5f520844a))

## [3.3.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.2.2...v3.3.0) (2023-08-18)


### Features

* adding parameters to triggers ([0d48466](https://github.com/craigulliott/dynamic_migrations/commit/0d484664dd344c34804580fb939a2807339a0552))


### Bug Fixes

* only accepting action_order for loaded triggers, and calculating its value dynamically for configured triggers ([0d48466](https://github.com/craigulliott/dynamic_migrations/commit/0d484664dd344c34804580fb939a2807339a0552))
* providing full function definition within specs (to conform with updated pg_spec_helper gem) ([0d48466](https://github.com/craigulliott/dynamic_migrations/commit/0d484664dd344c34804580fb939a2807339a0552))
* removing unused action_statement from triggers ([0d48466](https://github.com/craigulliott/dynamic_migrations/commit/0d484664dd344c34804580fb939a2807339a0552))

## [3.2.2](https://github.com/craigulliott/dynamic_migrations/compare/v3.2.1...v3.2.2) (2023-08-17)


### Bug Fixes

* automatically strip whitespace off validation check_clause ([f7a3b91](https://github.com/craigulliott/dynamic_migrations/commit/f7a3b91e694db83a5aefcd25e50985c05aaf97e2))

## [3.2.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.2.0...v3.2.1) (2023-08-17)


### Bug Fixes

* making column descriptions optional ([c384225](https://github.com/craigulliott/dynamic_migrations/commit/c3842254841c677efb777a1beb519754a4e85cc1))
* trimming object descriptions when saving ([c384225](https://github.com/craigulliott/dynamic_migrations/commit/c3842254841c677efb777a1beb519754a4e85cc1))

## [3.2.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.1.1...v3.2.0) (2023-08-16)


### Features

* adding a with_connection method to the database which yields to a block, and provides a connection object to that block ([fc1590a](https://github.com/craigulliott/dynamic_migrations/commit/fc1590a00be8d3f9f0ee0472a96be94b80e667e0))

## [3.1.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.1.0...v3.1.1) (2023-08-16)


### Bug Fixes

* refactoring the migration generator so that it handles dependencies between migrations ([8d0f8d8](https://github.com/craigulliott/dynamic_migrations/commit/8d0f8d8cd4a22b974b6449c62ad2a2d74aeffb2e))

## [3.1.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.0.0...v3.1.0) (2023-08-14)


### Features

* adding a convenience method `to_migrations` on the differences class ([efe94be](https://github.com/craigulliott/dynamic_migrations/commit/efe94be9c620fc44d1cdba54f6cd365292ae0f34))


### Bug Fixes

* updating to_migrations method signature in differences class ([e4e502b](https://github.com/craigulliott/dynamic_migrations/commit/e4e502b7ec44add3d2b6727869a4ad90bc7531b7))

## [3.0.0](https://github.com/craigulliott/dynamic_migrations/compare/v2.2.0...v3.0.0) (2023-08-11)


### ⚠ BREAKING CHANGES

* functions and triggers, removed unusable index_type from primary key and unique constraints, added active record migrations and some general refactoring

### Features

* adding migration generators and active record migrators ([80bf481](https://github.com/craigulliott/dynamic_migrations/commit/80bf481bfd33941b8380e7deb010b171898c03df))
* functions and triggers, removed unusable index_type from primary key and unique constraints, added active record migrations and some general refactoring ([45fcb7c](https://github.com/craigulliott/dynamic_migrations/commit/45fcb7ca3b6724625a4868198a9e75aefb1ea964))
* now generating migrations from all database structure object types ([871ab04](https://github.com/craigulliott/dynamic_migrations/commit/871ab048efb6247bc7fadb6e49bb15f6933c5586))
* various improvements to triggers and functions, and other general improvements ([e7dd9ab](https://github.com/craigulliott/dynamic_migrations/commit/e7dd9abeee736ea2791c192d3f797497f54773b4))

## [2.2.0](https://github.com/craigulliott/dynamic_migrations/compare/v2.1.0...v2.2.0) (2023-07-31)


### Features

* using postgres shorthand names such as `numeric(12,2)` for types, and removing the additional column metadata ([86d0113](https://github.com/craigulliott/dynamic_migrations/commit/86d0113aabd4350f278164d18e3c0a611fcf5595))

## [2.1.0](https://github.com/craigulliott/dynamic_migrations/compare/v2.0.0...v2.1.0) (2023-07-31)


### Features

* apply default column values to column data types ([6911c5f](https://github.com/craigulliott/dynamic_migrations/commit/6911c5f2026b47ef2e9f7bc529f7ff0d8f098700))

## [2.0.0](https://github.com/craigulliott/dynamic_migrations/compare/v1.1.1...v2.0.0) (2023-07-27)


### ⚠ BREAKING CHANGES

* changing all name related methods from `%object%_name` to just `name` (i.e. `table.table_name` is now just `table.name`)

### Features

* changing all name related methods from `%object%_name` to just `name` (i.e. `table.table_name` is now just `table.name`) ([77f18ae](https://github.com/craigulliott/dynamic_migrations/commit/77f18ae168c2449fa437fa7692ff9339931f9076))

## [1.1.1](https://github.com/craigulliott/dynamic_migrations/compare/v1.1.0...v1.1.1) (2023-07-17)


### Bug Fixes

* validating that new databases don't already exist and removing a debug print statement ([73bed2d](https://github.com/craigulliott/dynamic_migrations/commit/73bed2d6ab928c7a8f53b2aa17a188a77ed369e9))

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
