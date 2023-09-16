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
  end
end
