# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Function do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, pg_helper.database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:function_definition) {
      <<~SQL
        BEGIN
          NEW.column = 0;
          RETURN NEW;
        END;
      SQL
    }

    describe :create_function do
      describe "for a function with a comment" do
        let(:function) { schema.add_function :my_function, function_definition, description: "Comment for this function" }

        it "should return the expected ruby syntax to add a function" do
          expect(generator.create_function(function).to_s).to eq <<~RUBY.strip
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
        end
      end
    end

    describe :update_function do
      describe "for a function with a comment" do
        let(:function) { schema.add_function :my_function, function_definition, description: "Comment for this function" }

        it "should return the expected ruby syntax to update a function" do
          expect(generator.update_function(function).to_s).to eq <<~RUBY.strip
            update_function :my_function do
              <<~SQL
                BEGIN
                  NEW.column = 0;
                  RETURN NEW;
                END;
              SQL
            end
          RUBY
        end
      end
    end

    describe :drop_function do
      describe "for simple function" do
        let(:function) { schema.add_function :my_function, function_definition }

        it "should return the expected ruby syntax to remove a function" do
          expect(generator.drop_function(function).to_s).to eq <<~RUBY.strip
            drop_function :my_function
          RUBY
        end
      end
    end

    describe :set_function_comment do
      describe "for simple function" do
        let(:function) { schema.add_function :my_function, function_definition, description: "My function comment" }

        it "should return the expected ruby syntax to set a function comment" do
          expect(generator.set_function_comment(function).to_s).to eq <<~RUBY.strip
            set_function_comment :my_function, <<~COMMENT
              My function comment
            COMMENT
          RUBY
        end
      end
    end

    describe :remove_function_comment do
      describe "for simple function" do
        let(:function) { schema.add_function :my_function, function_definition, description: "My function comment" }

        it "should return the expected ruby syntax to remove a function comment" do
          expect(generator.remove_function_comment(function).to_s).to eq <<~RUBY.strip
            remove_function_comment :my_function
          RUBY
        end
      end
    end

    describe :optional_function_table do
      describe "for simple function not associated to any triggers" do
        let(:function) { schema.add_function :my_function, function_definition, description: "My function comment" }

        it "should return nil" do
          expect(generator.optional_function_table(function)).to be_nil
        end
      end

      describe "for simple function not associated to a trigger" do
        let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
        let(:function) { schema.add_function :my_function, function_definition, description: "My function comment" }
        let(:trigger) { table.add_trigger :my_trigger, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: ["true"], action_orientation: :statement, action_timing: :before, function: function, description: "Comment for this trigger" }

        before(:each) do
          trigger
        end

        it "should return the table" do
          expect(generator.optional_function_table(function)).to eq function.triggers.first.table
        end

        describe "when the function is associated to another trigger on the same table" do
          let(:trigger2) { table.add_trigger :my_trigger2, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: ["true"], action_orientation: :statement, action_timing: :before, function: function, description: "Comment for this trigger" }

          before(:each) do
            trigger2
          end

          it "should return the table" do
            expect(generator.optional_function_table(function)).to eq function.triggers.first.table
          end
        end

        describe "when the function is associated to another trigger on a different table" do
          let(:table2) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table2, description: "Comment for this table" }
          let(:trigger2) { table2.add_trigger :my_trigger2, event_manipulation: :insert, action_order: nil, action_condition: nil, parameters: ["true"], action_orientation: :statement, action_timing: :before, function: function, description: "Comment for this trigger" }

          before(:each) do
            trigger2
          end

          it "should return the table" do
            expect(generator.optional_function_table(function)).to be_nil
          end
        end
      end
    end
  end
end
