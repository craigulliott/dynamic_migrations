# Changelog

## [3.8.7](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.6...v3.8.7) (2023-10-09)


### Bug Fixes

* added detection of missing extensions and better error messages when normalizing check_constrains and action_conditions ([d82ff57](https://github.com/craigulliott/dynamic_migrations/commit/d82ff57f5b51c8636e87b40b8d6b016d11e6c72a))
* added enum value length validation ([d82ff57](https://github.com/craigulliott/dynamic_migrations/commit/d82ff57f5b51c8636e87b40b8d6b016d11e6c72a))
* also drastic performance improvement of migration circular dependency resolution ([2915b8f](https://github.com/craigulliott/dynamic_migrations/commit/2915b8f28c9202bd18f221cfafa2c4352a80fd2c))
* fixed regex for validating name within migration fragment (it was not allowing a single letter followed by an underscore) ([9b73eca](https://github.com/craigulliott/dynamic_migrations/commit/9b73ecac03816cc74f9b0d23084d0cfb09701012))
* migration generation now finds and resolves circular dependencies which exist through N migrations (it used to only resolve immediate circular dependencies) ([2915b8f](https://github.com/craigulliott/dynamic_migrations/commit/2915b8f28c9202bd18f221cfafa2c4352a80fd2c))
* providing the table dependency to all enum and function migrations if there is only one table which they rely on ([3d3708d](https://github.com/craigulliott/dynamic_migrations/commit/3d3708dfb7bdd2a83a477087ac22fd540ae1f881))
* reducing some log messages from info level to debug level ([cdf1200](https://github.com/craigulliott/dynamic_migrations/commit/cdf12000186a9e373d5085f83d2fb197c7796c6c))
* table migrations now allow enum related fragments ([b894bf1](https://github.com/craigulliott/dynamic_migrations/commit/b894bf14743c51b505693818407ba6bfb3f31571))
* updating log level for some log entries ([456a90e](https://github.com/craigulliott/dynamic_migrations/commit/456a90e7fe6da78667a84928b75217f89c344f35))

## [3.8.6](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.5...v3.8.6) (2023-10-08)


### Bug Fixes

* replacing enum casts with the temporary enums when normalizing check clause and action conditions ([0cb67fc](https://github.com/craigulliott/dynamic_migrations/commit/0cb67fcff4d7833ec1dd60453526b1bc3dbe45ee))

## [3.8.5](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.4...v3.8.5) (2023-10-08)


### Bug Fixes

* missing error class ([761e478](https://github.com/craigulliott/dynamic_migrations/commit/761e478fbd9234014751d853da3dde35d2043a7e))
* normalized validation check constraint and trigger action condition now work with enum columns ([a657dd6](https://github.com/craigulliott/dynamic_migrations/commit/a657dd66f3bb3e140672db89224b0b562bb91ef0))

## [3.8.4](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.3...v3.8.4) (2023-10-06)


### Bug Fixes

* asserting that enum values must be unique strings, and adding ability to add additional enum values ([5cf6093](https://github.com/craigulliott/dynamic_migrations/commit/5cf6093eed96387042f70987c3999b40e4041b76))

## [3.8.3](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.2...v3.8.3) (2023-10-06)


### Bug Fixes

* adding logging ([1387a75](https://github.com/craigulliott/dynamic_migrations/commit/1387a7535db242570b2b9fa60730d6bd73edb265))

## [3.8.2](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.1...v3.8.2) (2023-10-06)


### Bug Fixes

* fetch_normalized_check_clause_and_column_names was using column names from the validation instead of the table it belonged to ([5157205](https://github.com/craigulliott/dynamic_migrations/commit/5157205fc52cfbf062d61054bf12c117a5df5b57))

## [3.8.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.8.0...v3.8.1) (2023-10-06)


### Bug Fixes

* reusing exiting connection when with_connection is called (it was trying to open a new connection and caused an error) ([840a5cd](https://github.com/craigulliott/dynamic_migrations/commit/840a5cda04d6bc49d73160d2bad7271780027c84))

## [3.8.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.7.0...v3.8.0) (2023-10-04)


### Features

* configuration option to skip removing unused extensions ([5d27e36](https://github.com/craigulliott/dynamic_migrations/commit/5d27e36363dcec552ed015a196fbcf660e6b038c))


### Bug Fixes

* adding a setting to allow customizing where the schema where materialized view structure caches are created ([f3a81f8](https://github.com/craigulliott/dynamic_migrations/commit/f3a81f850dacc40ee434de77bb1d3f3c14ea0872))
* handling arrays of enums properly ([5d27e36](https://github.com/craigulliott/dynamic_migrations/commit/5d27e36363dcec552ed015a196fbcf660e6b038c))
* skipping views when loading database tables ([5d27e36](https://github.com/craigulliott/dynamic_migrations/commit/5d27e36363dcec552ed015a196fbcf660e6b038c))

## [3.7.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.16...v3.7.0) (2023-09-27)


### Features

* providing access to foreign key constraints from both sides of the association ([48dcf1c](https://github.com/craigulliott/dynamic_migrations/commit/48dcf1cd4cdb23bc37da3e47b00f8007b8bc0f8a))


### Bug Fixes

* allowing foreign keys to the same table because they are valid and sometimes useful ([0566384](https://github.com/craigulliott/dynamic_migrations/commit/0566384a4cfeade757d9806059035477f7c41ee2))
* lazy loading column names for validations when they were configured with a nil value for columns ([439200e](https://github.com/craigulliott/dynamic_migrations/commit/439200efdedf74dddc852bf9bd35e81c1f6b4336))
* providing convenience method to retrieve columns base data type from array columns ([cd3d9bf](https://github.com/craigulliott/dynamic_migrations/commit/cd3d9bf06682335a890d9b11133d397d7bcd50af))
* semi colon at the end of function definitions is now optional ([ca9b3aa](https://github.com/craigulliott/dynamic_migrations/commit/ca9b3aa04da23605ff61b2ec14baed927145d2c3))
* structure loader was not identifying enums properly ([95276d3](https://github.com/craigulliott/dynamic_migrations/commit/95276d33f98f41eca9a9467bb6abeb458a37f16b))

## [3.6.16](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.15...v3.6.16) (2023-09-16)


### Bug Fixes

* adding convenience method to call all three cache rebuild methods at once ([287a73d](https://github.com/craigulliott/dynamic_migrations/commit/287a73d96c4bfa303150e3c1f65cb514569c03b6))
* allowing functions and triggers to be in different schemas ([6df3377](https://github.com/craigulliott/dynamic_migrations/commit/6df337780a9a6b6815776a1f65afd3c8325a00fd))
* always sorting column names on validations so that they match the structure loader ([3e7e646](https://github.com/craigulliott/dynamic_migrations/commit/3e7e646e834140bcce74e357e6e84c3996b9525e))
* corrected bug where we passed nil as trigger for updating trigger comment ([c7a3677](https://github.com/craigulliott/dynamic_migrations/commit/c7a3677694130125d581f8f68e56865644d5c442))
* enum values should be strings not symbols ([080e5da](https://github.com/craigulliott/dynamic_migrations/commit/080e5daaeefa1504912e2cd4f3482af82890ee08))
* fixed bug where constraint was duplicated due to pg check_constraints table allowing duplicates ([471b6f8](https://github.com/craigulliott/dynamic_migrations/commit/471b6f82fc01770e63f657a12d01d18011c69f07))
* fixing whitespace with create table migrator syntax ([5bf1a7f](https://github.com/craigulliott/dynamic_migrations/commit/5bf1a7f9f337883ca677b1a2015dd0c41a27442c))
* generating materialized views automatically when refreshing them but they don't yet exist ([471b6f8](https://github.com/craigulliott/dynamic_migrations/commit/471b6f82fc01770e63f657a12d01d18011c69f07))
* handling default comments via templates ([3e7e646](https://github.com/craigulliott/dynamic_migrations/commit/3e7e646e834140bcce74e357e6e84c3996b9525e))
* methods to refresh caches because this needs to be performed before and after migrations are generated and run ([ab72670](https://github.com/craigulliott/dynamic_migrations/commit/ab72670e5fc7d379aed86cf72be956cdc39ed620))
* more strictly validating column types data types which use enums ([3e7e646](https://github.com/craigulliott/dynamic_migrations/commit/3e7e646e834140bcce74e357e6e84c3996b9525e))
* removed code which was stripping empty lines from migrations, but inadvertently removing empty lines from within SQL statements ([3e7e646](https://github.com/craigulliott/dynamic_migrations/commit/3e7e646e834140bcce74e357e6e84c3996b9525e))
* updating action order so that its sequential based on the event manipulation type (update, insert etc.) ([3e7e646](https://github.com/craigulliott/dynamic_migrations/commit/3e7e646e834140bcce74e357e6e84c3996b9525e))
* validations should not end with a semicolon ([9e2cc8e](https://github.com/craigulliott/dynamic_migrations/commit/9e2cc8ebf1c6da8c4741c5257c6567fc9f3668a7))
* various fixes after running a variety of real migrations from platformer ([301db01](https://github.com/craigulliott/dynamic_migrations/commit/301db01397f1cb16c6c0e08e9e8c69e1f3ec799e))

## [3.6.15](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.14...v3.6.15) (2023-09-14)


### Bug Fixes

* missing colon before foreign schema name in migration generator ([b94ad92](https://github.com/craigulliott/dynamic_migrations/commit/b94ad924c7ead5ad697ea4fb48871ac827ad5c85))

## [3.6.14](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.13...v3.6.14) (2023-09-14)


### Bug Fixes

* allowing templates to return nil and skip adding to migrations ([3d90829](https://github.com/craigulliott/dynamic_migrations/commit/3d9082960403899b4243fde60629d9c83ce1e263))

## [3.6.13](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.12...v3.6.13) (2023-09-14)


### Bug Fixes

* providing foreign_schema_name to create foreign key constraint, and only providing non default arguments ([e45d499](https://github.com/craigulliott/dynamic_migrations/commit/e45d4994a9b947f0d626bdd4b0e2a36136412370))

## [3.6.12](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.11...v3.6.12) (2023-09-13)


### Bug Fixes

* removing unused argument for create_function migrator ([bdb2ad5](https://github.com/craigulliott/dynamic_migrations/commit/bdb2ad58ff0c5aa3520eb38ab0d16b823014ce6e))

## [3.6.11](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.10...v3.6.11) (2023-09-13)


### Bug Fixes

* injecting dependent_function into templated triggers ([9e770a3](https://github.com/craigulliott/dynamic_migrations/commit/9e770a352b176c7b10471e9185ac01feca538c0c))
* writing enums to the migration files as arrays of strings for more compatibility with special characters ([1910e0f](https://github.com/craigulliott/dynamic_migrations/commit/1910e0f709e5bd560696c2e2b3bd729c7a61e319))

## [3.6.10](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.9...v3.6.10) (2023-09-13)


### Bug Fixes

* only concerned about function and enum dependencies if they are in other schemas or have multiple objects which reference them ([ee42670](https://github.com/craigulliott/dynamic_migrations/commit/ee426704d56329cd4ae450d93308097a4419ee63))
* some extensions have hyphens in their names, coercing them to underscores so that this does not break the migration class name ([0b2396b](https://github.com/craigulliott/dynamic_migrations/commit/0b2396b171f6d1eeb8dc4567658937576357ba2a))

## [3.6.9](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.8...v3.6.9) (2023-09-13)


### Bug Fixes

* enum name as a data type should include the schema name ([7658d14](https://github.com/craigulliott/dynamic_migrations/commit/7658d1482b7e50bcce11268d8121ee59ae194fa3))

## [3.6.8](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.7...v3.6.8) (2023-09-13)


### Bug Fixes

* dependency resolution is now aware of functions, enums and works across schemas. ([460de82](https://github.com/craigulliott/dynamic_migrations/commit/460de828be1826930bc1b185cf2a4c4e354d7dad))
* enum columns now accept an enum object ([460de82](https://github.com/craigulliott/dynamic_migrations/commit/460de828be1826930bc1b185cf2a4c4e354d7dad))
* trigger parameters is now an array of strings ([460de82](https://github.com/craigulliott/dynamic_migrations/commit/460de828be1826930bc1b185cf2a4c4e354d7dad))

## [3.6.7](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.6...v3.6.7) (2023-09-13)


### Bug Fixes

* removing duplicate single quotes ([8d7eb44](https://github.com/craigulliott/dynamic_migrations/commit/8d7eb447fef0a702cacb37714905dcb85728a821))
* updating spec `quot` method to match active records implementation ([674a7d8](https://github.com/craigulliott/dynamic_migrations/commit/674a7d86bbf70ee8304ade2539344ed26ef2a650))

## [3.6.6](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.5...v3.6.6) (2023-09-13)


### Bug Fixes

* column_name and data_type were presented in the wrong order ([e58f8df](https://github.com/craigulliott/dynamic_migrations/commit/e58f8df7d2acabc8a64f760d6ababe218a23928d))

## [3.6.5](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.4...v3.6.5) (2023-09-13)


### Bug Fixes

* setting current schema on the migration class instead of the shared module ([28bc2ca](https://github.com/craigulliott/dynamic_migrations/commit/28bc2ca454883696665804c8596fc3b19ce31bb4))

## [3.6.4](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.3...v3.6.4) (2023-09-13)


### Bug Fixes

* using active records standard disable/enable_extension, and create/drop schema methods ([4a73e5c](https://github.com/craigulliott/dynamic_migrations/commit/4a73e5c2d6642bdd9c5f61164a044bbed9032da9))

## [3.6.3](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.2...v3.6.3) (2023-09-13)


### Bug Fixes

* passing correct type when generating column migrations ([e345d56](https://github.com/craigulliott/dynamic_migrations/commit/e345d56cdb11bb965c71c251d82ce2087b416f47))

## [3.6.2](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.1...v3.6.2) (2023-09-13)


### Bug Fixes

* don't generate columns separately for migrations if also generating the table (as they are already included in the table definition) ([b6f748c](https://github.com/craigulliott/dynamic_migrations/commit/b6f748c8e72aaab12d32243f6a007d03707041da))

## [3.6.1](https://github.com/craigulliott/dynamic_migrations/compare/v3.6.0...v3.6.1) (2023-09-13)


### Bug Fixes

* adding attr_reader for :code_comment to provide easier access within migration templates ([b805e24](https://github.com/craigulliott/dynamic_migrations/commit/b805e247ef42ea4dd62973be07057d6e110876a3))

## [3.6.0](https://github.com/craigulliott/dynamic_migrations/compare/v3.5.3...v3.6.0) (2023-09-13)


### Features

* plugin architecture for validation and trigger templates (allows for creating cleaner migrations with custom methods) ([f4e9d5e](https://github.com/craigulliott/dynamic_migrations/commit/f4e9d5eae803196e727a5b4d7314e773cd90ba00))


### Bug Fixes

* fixed badly generated trigger migration ([f4e9d5e](https://github.com/craigulliott/dynamic_migrations/commit/f4e9d5eae803196e727a5b4d7314e773cd90ba00))

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
