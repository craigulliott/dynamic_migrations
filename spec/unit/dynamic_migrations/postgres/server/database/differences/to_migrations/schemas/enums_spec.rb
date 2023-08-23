# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations::Schemas do
  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
  let(:differences) { DynamicMigrations::Postgres::Server::Database::Differences.new database }
  let(:to_migrations) { DynamicMigrations::Postgres::Server::Database::Differences::ToMigrations.new database, differences }
  let(:enum_values) { [:foo, :bar] }

  describe :Enums do
    describe :migrations do
      describe "when the loaded and configured database have the same schema" do
        let(:configured_schema) { database.add_configured_schema :my_schema }
        let(:loaded_schema) { database.add_loaded_schema :my_schema }

        before(:each) do
          configured_schema
          loaded_schema
        end

        describe "when the configured schema has a enum" do
          before(:each) do
            configured_schema.add_enum :my_enum, enum_values
          end

          it "returns the migration to create the enum" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :enums,
                content: <<~RUBY.strip
                  #
                  # Enums
                  #
                  create_enum :my_enum, [
                    :foo,
                    :bar
                  ]
                RUBY
              }
            ])
          end

          describe "when the loaded database has the same enum but missing enum values" do
            before(:each) do
              loaded_schema.add_enum :my_enum, enum_values - [:foo]
            end

            it "returns the migration to update the enum" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :enums,
                content: <<~RUBY.strip
                  #
                  # Enums
                  #
                  add_enum_values :my_enum, [
                    :foo
                  ]
                RUBY
              }])
            end
          end

          describe "when the loaded database has an equivalent enum" do
            before(:each) do
              loaded_schema.add_enum :my_enum, enum_values
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end

        describe "when the configured schema has a enum with a description" do
          before(:each) do
            configured_schema.add_enum :my_enum, enum_values, description: "Description of my enum"
          end

          it "returns the migration to create the enum and description" do
            expect(to_migrations.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :enums,
                content: <<~RUBY.strip
                  #
                  # Enums
                  #
                  create_enum :my_enum, [
                    :foo,
                    :bar
                  ]

                  set_enum_comment :my_enum, <<~COMMENT
                    Description of my enum
                  COMMENT
                RUBY
              }
            ])
          end

          describe "when the loaded schema has the same enum but a different description" do
            before(:each) do
              loaded_schema.add_enum :my_enum, enum_values, description: "Different description of my enum"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :enums,
                content: <<~RUBY.strip
                  #
                  # Enums
                  #
                  set_enum_comment :my_enum, <<~COMMENT
                    Description of my enum
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded schema has the same enum but a different description and values" do
            before(:each) do
              loaded_schema.add_enum :my_enum, enum_values - [:bar], description: "Different description of my enum"
            end

            it "returns the migration to update the description" do
              expect(to_migrations.migrations).to eql([{
                schema_name: :my_schema,
                name: :enums,
                content: <<~RUBY.strip
                  #
                  # Enums
                  #
                  add_enum_values :my_enum, [
                    :bar
                  ]

                  set_enum_comment :my_enum, <<~COMMENT
                    Description of my enum
                  COMMENT
                RUBY
              }])
            end
          end

          describe "when the loaded schema has an equivalent enum and description" do
            before(:each) do
              loaded_schema.add_enum :my_enum, enum_values, description: "Description of my enum"
            end

            it "returns no migrations because there are no differences" do
              expect(to_migrations.migrations).to eql([])
            end
          end
        end
      end
    end
  end
end
