# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator do
  let(:generator) { DynamicMigrations::Postgres::Generator.new }

  describe :Table do
    let(:pg_helper) { RSpec.configuration.pg_spec_helper }
    let(:server) { DynamicMigrations::Postgres::Server.new pg_helper.host, pg_helper.port, pg_helper.username, pg_helper.password }
    let(:database) { DynamicMigrations::Postgres::Server::Database.new server, :my_database }
    let(:schema) { DynamicMigrations::Postgres::Server::Database::Schema.new :configuration, database, :my_schema }
    let(:table) { DynamicMigrations::Postgres::Server::Database::Schema::Table.new :configuration, schema, :my_table, description: "Comment for this table" }
    let(:enum) { DynamicMigrations::Postgres::Server::Database::Schema::Enum.new :configuration, schema, :my_enum, enum_values }
    let(:enum_values) { [:foo, :bar] }

    describe :create_table do
      describe "for a table with no columns" do
        it "should return the expected ruby syntax to create a table" do
          expect(generator.create_table(table).map(&:to_s)).to eql [
            <<~RUBY.strip
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: false, comment: table_comment do |t|
              end
            RUBY
          ]
        end
      end

      describe "for a table with a uuid primary key" do
        before(:each) do
          table.add_column :id, :uuid, null: false, default: "uuid_generate_v4()", description: "Comment for this column"
          table.add_primary_key :my_table_primary_key_name, [:id]
        end

        it "should return the expected ruby syntax to create a table" do
          expect(generator.create_table(table).map(&:to_s)).to eql [
            <<~RUBY.strip
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: :uuid, comment: table_comment do |t|
              end
            RUBY
          ]
        end
      end

      describe "for a table with created_at" do
        before(:each) do
          table.add_column :created_at, :timestamp
        end

        it "should return the expected ruby syntax to create a table" do
          expect(generator.create_table(table).map(&:to_s)).to eql [
            <<~RUBY.strip
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: false, comment: table_comment do |t|
                t.timestamps :created_at
              end
            RUBY
          ]
        end
      end

      describe "for a table with created_at and updated_at" do
        before(:each) do
          table.add_column :created_at, :timestamp
          table.add_column :updated_at, :timestamp
        end

        it "should return the expected ruby syntax to create a table" do
          expect(generator.create_table(table).map(&:to_s)).to eql [
            <<~RUBY.strip
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: false, comment: table_comment do |t|
                t.timestamps :created_at, :updated_at
              end
            RUBY
          ]
        end
      end

      describe "for a table with two other colums" do
        before(:each) do
          table.add_column :foo, :varchar, null: false, default: "foo", description: "Comment for this column"
          table.add_column :bar, :varchar, null: false, default: "foo", description: "Comment for this column"
        end

        it "should return the expected ruby syntax to create a table" do
          expect(generator.create_table(table).map(&:to_s)).to eql [
            <<~RUBY.strip
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: false, comment: table_comment do |t|
                t.column :bar, :varchar, null: false, default: "foo", comment: <<~COMMENT
                  Comment for this column
                COMMENT
                t.column :foo, :varchar, null: false, default: "foo", comment: <<~COMMENT
                  Comment for this column
                COMMENT
              end
            RUBY
          ]
        end
      end

      describe "for a table with one varchar and one enum column" do
        before(:each) do
          table.add_column :foo, :"my_schema.my_enum", enum: enum, null: false, description: "Comment for this column"
          table.add_column :bar, :varchar, null: false, description: "Comment for this column"
        end

        it "should return the expected ruby syntax to create a table" do
          create_table = <<~RUBY.strip
            table_comment = <<~COMMENT
              Comment for this table
            COMMENT
            create_table :my_table, id: false, comment: table_comment do |t|
              t.column :bar, :varchar, null: false, comment: <<~COMMENT
                Comment for this column
              COMMENT
            end
          RUBY
          add_column = <<~RUBY.strip
            add_column :my_table, :foo, "my_schema.my_enum", null: false, comment: <<~COMMENT
              Comment for this column
            COMMENT
          RUBY

          expect(generator.create_table(table).map(&:to_s)).to eql [create_table, add_column]
        end
      end

      describe "for a table with a composite primary key" do
        before(:each) do
          table.add_column :a, :uuid, null: false, description: "Part one of the composite primary key"
          table.add_column :b, :uuid, null: false, description: "Part two of the composite primary key"
          table.add_primary_key :my_table_primary_key_name, [:a, :b]
        end

        it "should return the expected ruby syntax to create a table" do
          expect(generator.create_table(table).map(&:to_s)).to eql [
            <<~RUBY.strip
              table_comment = <<~COMMENT
                Comment for this table
              COMMENT
              create_table :my_table, id: false, primary_key: [:a, :b], comment: table_comment do |t|
                t.column :a, :uuid, null: false, comment: <<~COMMENT
                  Part one of the composite primary key
                COMMENT
                t.column :b, :uuid, null: false, comment: <<~COMMENT
                  Part two of the composite primary key
                COMMENT
              end
            RUBY
          ]
        end
      end
    end

    describe :drop_table do
      it "should return the expected ruby syntax to drop a table" do
        expect(generator.drop_table(table).to_s).to eq <<~RUBY.strip
          drop_table :my_table, force: true
        RUBY
      end
    end

    describe :set_table_comment do
      it "should return the expected ruby syntax to set a table comment" do
        expect(generator.set_table_comment(table).to_s).to eq <<~RUBY.strip
          set_table_comment :my_table, <<~COMMENT
            Comment for this table
          COMMENT
        RUBY
      end
    end

    describe :remove_table_comment do
      it "should return the expected ruby syntax to remove a table comment" do
        expect(generator.remove_table_comment(table).to_s).to eq <<~RUBY.strip
          remove_table_comment :my_table
        RUBY
      end
    end
  end
end
