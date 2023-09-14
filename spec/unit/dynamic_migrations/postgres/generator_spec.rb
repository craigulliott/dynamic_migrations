# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  let(:pg_helper) { RSpec.configuration.pg_spec_helper }
  let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
  let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }

  let(:schema) { database.add_configured_schema :my_schema }
  let(:table) { schema.add_table :my_table, description: "Comment for this table" }
  let(:table2) { schema.add_table :my_other_table, description: "Comment for this table" }

  describe :migrations do
    describe "for a table with uuid primary key, timestamps, and two other colums" do
      before(:each) do
        table.add_column :id, :uuid, null: false, default: "uuid_generate_v4()"
        table.add_primary_key :my_table_primary_key_name, [:id]
        table.add_column :foo, :varchar, null: false, default: "foo", description: "Comment for this column"
        table.add_column :bar, :varchar, null: false, default: "foo", description: "Comment for this column"
        table.add_column :created_at, :timestamp
        table.add_column :updated_at, :timestamp

        generator.create_table(table)
      end

      it "should return the expected ruby syntax to create a table" do
        expect(generator.migrations).to eql([
          {
            schema_name: :my_schema,
            name: :create_my_table,
            content: <<~RUBY.strip
              #
              # Create Table
              #
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: :uuid, comment: table_comment do |t|
                t.column :bar, :varchar, null: false, default: "foo", comment: <<~COMMENT
                  Comment for this column
                COMMENT
                t.column :foo, :varchar, null: false, default: "foo", comment: <<~COMMENT
                  Comment for this column
                COMMENT
                t.timestamps :created_at, :updated_at
              end
            RUBY
          }
        ])
      end
    end

    describe "for one schema with two simple tables" do
      before(:each) do
        table.add_column :id, :integer, null: false, description: "Comment for this column"
        table.add_column :table_id, :integer, null: false, description: "Comment for this column"
        generator.create_table(table)

        table2.add_column :id, :integer, null: false, description: "Comment for this column"
        table2.add_column :table_id, :integer, null: false, description: "Comment for this column"
        generator.create_table(table2)
      end

      it "should return the expected ruby syntax to create two tables" do
        expect(generator.migrations).to eql([
          {
            schema_name: :my_schema,
            name: :create_my_table,
            content: <<~RUBY.strip
              #
              # Create Table
              #
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: :integer, comment: table_comment do |t|
                t.column :table_id, :integer, null: false, comment: <<~COMMENT
                  Comment for this column
                COMMENT
              end
            RUBY
          },
          {
            schema_name: :my_schema,
            name: :create_my_other_table,
            content: <<~RUBY.strip
              #
              # Create Table
              #
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_other_table, id: :integer, comment: table_comment do |t|
                t.column :table_id, :integer, null: false, comment: <<~COMMENT
                  Comment for this column
                COMMENT
              end
            RUBY
          }
        ])
      end

      describe "when table has a foreign key to table2" do
        before(:each) do
          foreign_key_constraint = table.add_foreign_key_constraint(:foreign_key_constraint_name, [:table_id], :my_schema, :my_other_table, [:id])
          generator.add_foreign_key_constraint(foreign_key_constraint)
        end

        it "should return the expected ruby syntax to create two tables (note that the migrations are now in the opposite order to the previous test)" do
          expect(generator.migrations).to eql([
            {
              schema_name: :my_schema,
              name: :create_my_other_table,
              content: <<~RUBY.strip
                #
                # Create Table
                #
                table_comment = <<~COMMENT
                  Comment for this table
                COMMENT
                create_table :my_other_table, id: :integer, comment: table_comment do |t|
                  t.column :table_id, :integer, null: false, comment: <<~COMMENT
                    Comment for this column
                  COMMENT
                end
              RUBY
            },
            {
              schema_name: :my_schema,
              name: :create_my_table,
              content: <<~RUBY.strip
                #
                # Create Table
                #
                table_comment = <<~COMMENT
                  Comment for this table
                COMMENT
                create_table :my_table, id: :integer, comment: table_comment do |t|
                  t.column :table_id, :integer, null: false, comment: <<~COMMENT
                    Comment for this column
                  COMMENT
                end

                #
                # Foreign Keys
                #
                add_foreign_key :my_table, :table_id, :my_other_table, :id, name: :foreign_key_constraint_name
              RUBY
            }
          ])
        end

        describe "when table2 has a foreign key back to table1 (a circular dependency)" do
          before(:each) do
            foreign_key_constraint = table2.add_foreign_key_constraint(:foreign_key_constraint2_name, [:table_id], :my_schema, :my_table, [:id])
            generator.add_foreign_key_constraint(foreign_key_constraint)
          end

          it "should return the expected ruby syntax to create two tables (note that the migrations are now in the opposite order to the previous test)" do
            expect(generator.migrations).to eql([
              {
                schema_name: :my_schema,
                name: :create_my_table,
                content: <<~RUBY.strip
                  #
                  # Create Table
                  #
                  table_comment = <<~COMMENT
                    Comment for this table
                  COMMENT
                  create_table :my_table, id: :integer, comment: table_comment do |t|
                    t.column :table_id, :integer, null: false, comment: <<~COMMENT
                      Comment for this column
                    COMMENT
                  end
                RUBY
              },
              {
                schema_name: :my_schema,
                name: :create_my_other_table,
                content: <<~RUBY.strip
                  #
                  # Create Table
                  #
                  table_comment = <<~COMMENT
                    Comment for this table
                  COMMENT
                  create_table :my_other_table, id: :integer, comment: table_comment do |t|
                    t.column :table_id, :integer, null: false, comment: <<~COMMENT
                      Comment for this column
                    COMMENT
                  end

                  #
                  # Foreign Keys
                  #
                  add_foreign_key :my_other_table, :table_id, :my_table, :id, name: :foreign_key_constraint2_name
                RUBY
              },
              {
                schema_name: :my_schema,
                name: :changes_for_my_table,
                content: <<~RUBY.strip
                  #
                  # Foreign Keys
                  #
                  add_foreign_key :my_table, :table_id, :my_other_table, :id, name: :foreign_key_constraint_name
                RUBY
              }
            ])
          end
        end
      end
    end

    describe "for two schemas and tables with cross schema dependencies" do
      let(:schema2) { database.add_configured_schema :my_other_schema }
      let(:schema2_table) { schema2.add_table :my_table, description: "Comment for this table" }
      let(:schema2_table2) { schema2.add_table :my_other_table, description: "Comment for this table" }

      let(:enum) { schema2.add_enum :my_enum, enum_values, description: "Comment for this enum" }
      let(:enum_values) { [:foo, :bar] }

      let(:function) { schema2.add_function :my_function, function_definition, description: "Comment for this function" }
      let(:function_definition) {
        <<~SQL
          BEGIN
            NEW.column = 0;
            RETURN NEW;
          END;
        SQL
      }

      let(:trigger) { table.add_trigger :trigger_for_function_in_another_schema, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: [], action_orientation: :row, action_timing: :before, function: function, description: "Comment for this trigger" }

      before(:each) do
        table.add_column :id, :integer, null: false, description: "Comment for this column"
        table.add_column :enum_from_another_schmea, enum.full_name, enum: enum, null: false, description: "Comment for this column"
        generator.create_table(table)

        generator.create_enum(enum)
        generator.add_trigger(trigger)
        generator.create_function(function)
      end

      it "should return the expected ruby syntax to create everything in the correct order" do
        create_enum_and_function = {
          schema_name: :my_other_schema,
          name: :changes,
          content: <<~RUBY.strip
            #
            # Enums
            #
            create_enum :my_enum, [
              "foo",
              "bar"
            ]

            #
            # Functions
            #
            my_function_comment = <<~COMMENT
              Comment for this function
            COMMENT
            create_function :my_function, comment: my_function_comment do
              <<~SQL
                BEGIN
                  NEW.column = 0;
                  RETURN NEW;
                END;
              SQL
            end

          RUBY
        }
        create_table = {
          schema_name: :my_schema,
          name: :create_my_table,
          content: <<~RUBY.strip
            #
            # Create Table
            #
            table_comment = <<~COMMENT
              Comment for this table
            COMMENT
            create_table :my_table, id: :integer, comment: table_comment do |t|
            end

            #
            # Additional Columns
            #
            add_column :my_table, :enum_from_another_schmea, "my_other_schema.my_enum", null: false, comment: <<~COMMENT
              Comment for this column
            COMMENT

            #
            # Triggers
            #
            before_insert :my_table, name: :trigger_for_function_in_another_schema, function_schema_name: :my_other_schema, function_name: :my_function, comment: <<~COMMENT
              Comment for this trigger
            COMMENT
          RUBY
        }

        expect(generator.migrations).to eql([create_enum_and_function, create_table])
      end
    end
  end
end
