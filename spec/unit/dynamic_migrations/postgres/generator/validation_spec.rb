# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Validation do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:column) { table.add_column :my_column, :integer, null: true, description: "Comment for this column" }

    describe :add_validation do
      describe "for simple validation on one column" do
        let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0" }

        it "should return the expected ruby syntax to add a validation" do
          expect(generator.add_validation(validation).to_s).to eq <<~RUBY.strip
            add_validation :my_table, name: :validation_name do
              <<~SQL
                my_column > 0
              SQL
            end
          RUBY
        end
      end

      describe "for simple validation on one column which has a description" do
        let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0", description: "My validation" }

        it "should return the expected ruby syntax to add a validation" do
          expect(generator.add_validation(validation).to_s).to eq <<~RUBY.strip
            validation_name_comment = <<~COMMENT
              My validation
            COMMENT
            add_validation :my_table, name: :validation_name, comment: validation_name_comment do
              <<~SQL
                my_column > 0
              SQL
            end
          RUBY
        end
      end

      describe "after a less than template has been installed into the migration generator" do
        let(:less_than_template_class) {
          Class.new(DynamicMigrations::Postgres::Generator::ValidationTemplateBase) do
            warn "not tested"
            def fragment_arguments
              assert_column_count! 1

              column_name = first_column.name
              value = value_from_check_clause(/\A\w+ < (?<value>-?\d+(?:\.\d+)?);\z/)
              options_string = name_and_description_options_string :"#{column_name}_lt"
              {
                schema: validation.table.schema,
                table: validation.table,
                migration_method: :add_validation,
                object: validation,
                code_comment: @code_comment,
                migration: <<~RUBY
                  validate_less_than :#{validation.table.name}, :#{column_name}, #{value}#{options_string}
                RUBY
              }
            end
          end
        }
        before(:each) do
          DynamicMigrations::Postgres::Generator::Validation.add_template :less_than, less_than_template_class
        end

        describe "for simple validation which uses the template" do
          let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :my_column_lt, "my_column < 0;", description: "My validation", template: :less_than }

          it "should return the expected ruby syntax to add a validation" do
            expect(generator.add_validation(validation).to_s).to eq <<~RUBY.strip
              validate_less_than :my_table, :my_column, 0, comment: <<~COMMENT
                My validation
              COMMENT
            RUBY
          end
        end
      end
    end

    describe :remove_validation do
      describe "for simple validation on one column" do
        let(:validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0" }

        it "should return the expected ruby syntax to remove a validation" do
          expect(generator.remove_validation(validation).to_s).to eq <<~RUBY.strip
            remove_validation :my_table, :validation_name
          RUBY
        end
      end
    end

    describe :recreate_validation do
      describe "for validations with different check_clauses" do
        let(:original_validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 0" }
        let(:updated_validation) { DynamicMigrations::Postgres::Server::Database::Schema::Table::Validation.new :configuration, table, [column], :validation_name, "my_column > 100" }

        it "should return the expected ruby syntax to recreate a validation" do
          remove = <<~RUBY.strip
            # Removing original validation because it has changed (it is recreated below)
            # Changes:
            #   normalized_check_clause changed from `(my_column > 0)` to `(my_column > 100)`
            remove_validation :my_table, :validation_name
          RUBY
          re_add = <<~RUBY.strip
            # Recreating this validation
            add_validation :my_table, name: :validation_name do
              <<~SQL
                my_column > 100
              SQL
            end
          RUBY
          expect(generator.recreate_validation(original_validation, updated_validation).map(&:to_s)).to eq [remove, re_add]
        end
      end
    end

    describe :set_validation_comment do
      let(:validation) { table.add_validation :my_validation, [column.name], "my_column > 0", description: "Comment for this validation" }

      it "should return the expected ruby syntax to set a validation comment" do
        expect(generator.set_validation_comment(validation).to_s).to eq <<~RUBY.strip
          set_validation_comment :my_table, :my_validation, <<~COMMENT
            Comment for this validation
          COMMENT
        RUBY
      end
    end

    describe :remove_validation_comment do
      let(:validation) { table.add_validation :my_validation, [column.name], "my_column > 0", description: "Comment for this validation" }

      it "should return the expected ruby syntax to remove a validation comment" do
        expect(generator.remove_validation_comment(validation).to_s).to eq <<~RUBY.strip
          remove_validation_comment :my_table, :my_validation
        RUBY
      end
    end
  end
end
