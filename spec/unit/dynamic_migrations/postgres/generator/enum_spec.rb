# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Enum do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:enum_values) { ["foo", "bar"] }

    describe :create_enum do
      describe "for a enum with a comment" do
        let(:enum) { schema.add_enum :my_enum, enum_values, description: "Comment for this enum" }

        it "should return the expected ruby syntax to add a enum" do
          expect(generator.create_enum(enum).to_s).to eq <<~RUBY.strip
            create_enum :my_enum, [
              "foo",
              "bar"
            ]
          RUBY
        end
      end
    end

    describe :update_enum do
      describe "for a enum with a comment" do
        let(:database_schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :database, database, :my_schema }

        let(:original_enum) { schema.add_enum :my_enum, enum_values, description: "Comment for this enum" }
        let(:updated_enum) { database_schema.add_enum :my_enum, enum_values + ["baz"], description: "Comment for this enum" }

        it "should return the expected ruby syntax to update a enum" do
          expect(generator.update_enum(original_enum, updated_enum).to_s).to eq <<~RUBY.strip
            add_enum_values :my_enum, [
              "baz"
            ]
          RUBY
        end
      end
    end

    describe :drop_enum do
      describe "for simple enum" do
        let(:enum) { schema.add_enum :my_enum, enum_values }

        it "should return the expected ruby syntax to remove a enum" do
          expect(generator.drop_enum(enum).to_s).to eq <<~RUBY.strip
            drop_enum :my_enum
          RUBY
        end
      end
    end

    describe :set_enum_comment do
      describe "for simple enum" do
        let(:enum) { schema.add_enum :my_enum, enum_values, description: "My enum comment" }

        it "should return the expected ruby syntax to set a enum comment" do
          expect(generator.set_enum_comment(enum).to_s).to eq <<~RUBY.strip
            set_enum_comment :my_enum, <<~COMMENT
              My enum comment
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_enum_comment do
      describe "for simple enum" do
        let(:enum) { schema.add_enum :my_enum, enum_values, description: "My enum comment" }

        it "should return the expected ruby syntax to remove a enum comment" do
          expect(generator.remove_enum_comment(enum).to_s).to eq <<~RUBY.strip
            remove_enum_comment :my_enum
          RUBY
        end
      end
    end
  end
end
