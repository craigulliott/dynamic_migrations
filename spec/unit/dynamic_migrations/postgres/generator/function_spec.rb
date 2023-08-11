# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Function do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }

    describe :create_function do
      describe "for a function with a comment" do
        let(:function) { schema.add_function :my_function, "NEW.column = 0", description: "Comment for this function" }

        it "should return the expected ruby syntax to add a function" do
          expect(generator.create_function(function).to_s).to eq <<~RUBY.strip
            my_function_comment = <<~COMMENT
              Comment for this function
            COMMENT
            create_function :my_function, comment: my_function_comment do
              <<~SQL
                NEW.column = 0;
              SQL
            end
          RUBY
        end
      end
    end

    describe :update_function do
      describe "for a function with a comment" do
        let(:function) { schema.add_function :my_function, "NEW.column = 0", description: "Comment for this function" }

        it "should return the expected ruby syntax to update a function" do
          expect(generator.update_function(function).to_s).to eq <<~RUBY.strip
            update_function :my_function do
              <<~SQL
                NEW.column = 0;
              SQL
            end
          RUBY
        end
      end
    end

    describe :drop_function do
      describe "for simple function" do
        let(:function) { schema.add_function :my_function, "NEW.column = 0" }

        it "should return the expected ruby syntax to remove a function" do
          expect(generator.drop_function(function).to_s).to eq <<~RUBY.strip
            drop_function :my_function
          RUBY
        end
      end
    end

    describe :set_function_comment do
      describe "for simple function" do
        let(:function) { schema.add_function :my_function, "NEW.column = 0", description: "My function comment" }

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
        let(:function) { schema.add_function :my_function, "NEW.column = 0", description: "My function comment" }

        it "should return the expected ruby syntax to remove a function comment" do
          expect(generator.remove_function_comment(function).to_s).to eq <<~RUBY.strip
            remove_function_comment :my_function
          RUBY
        end
      end
    end
  end
end
