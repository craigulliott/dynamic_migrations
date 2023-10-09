# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          # This class represents a postgres table.
          class Table < Source
            class ExpectedSchemaError < StandardError
            end

            class PrimaryKeyDoesNotExistError < StandardError
            end

            class PrimaryKeyAlreadyExistsError < StandardError
            end

            class MissingExtensionError < StandardError
            end

            include Columns
            include Validations
            include Indexes
            include ForeignKeyConstraints
            include Triggers
            include UniqueConstraints

            attr_reader :schema
            attr_reader :name
            attr_reader :description
            attr_reader :remote_foreign_key_constraints

            # initialize a new object to represent a postgres table
            def initialize source, schema, name, description: nil
              super source

              raise ExpectedSchemaError, schema unless schema.is_a? Schema
              @schema = schema

              raise ExpectedSymbolError, name unless name.is_a? Symbol
              @name = name

              unless description.nil?
                raise ExpectedStringError, description unless description.is_a? String
                @description = description.strip
                @description = nil if description == ""
              end

              @columns = {}
              @validations = {}
              @indexes = {}
              @foreign_key_constraints = {}
              @remote_foreign_key_constraints = []
              @triggers = {}
              @unique_constraints = {}
            end

            # returns true if this table has a description, otehrwise false
            def has_description?
              !@description.nil?
            end

            # add a primary key to this table
            def add_primary_key name, column_names, **primary_key_options
              raise PrimaryKeyAlreadyExistsError if @primary_key
              columns = column_names.map { |column_name| column column_name }
              @primary_key = PrimaryKey.new source, self, columns, name, **primary_key_options
            end

            # returns true if this table has a primary key, otherwise false
            def has_primary_key?
              !@primary_key.nil?
            end

            # returns a primary key if one exists, else raises an error
            def primary_key
              pk = @primary_key
              unless pk
                raise PrimaryKeyDoesNotExistError
              end
              pk
            end

            # Used within validations and triggers when normalizing check clauses and other
            # SQL statements which require a table to process the SQL.
            #
            # This method returns a hash representation of any temporary enums created to satisfy
            # the columns in the table
            def create_temp_table connection, temp_table_name
              # create the temp table and add the expected columns

              # if any of the columns are enums, then we need to create a temporary enum type for them.
              # we cant just create temporary columns as text fields because postgres may automatically
              # add casts to those columns, which would result in a different normalized check clause
              temp_enums = {}

              # an array of sql column definitions for within the create table SQL
              # we process each column individually like this so that we can create temporary enums for
              # any enum columns
              columns_sql = columns.map do |column|
                enum = column.enum
                if enum
                  # create the temporary enum type
                  temp_enum_name = "#{temp_table_name}_enum_#{temp_enums.count}"
                  connection.exec(<<~SQL)
                    CREATE TYPE #{temp_enum_name} as ENUM ('#{enum.values.join("','")}');
                  SQL
                  temp_enums[temp_enum_name] = enum

                  # return the column definition used within the CREATE TABLE SQL
                  data_type = column.array? ? "#{temp_enum_name}[]" : temp_enum_name
                  "\"#{column.name}\" #{data_type}"

                else
                  # return the column definition used within the CREATE TABLE SQL
                  "\"#{column.name}\" #{column.data_type}"
                end
              end

              # in case any of the columnbs are citext columns
              # in case any of the columns use the citext data type
              required_extensions = []
              if columns.any? { |column| column.data_type.start_with? "citext" }
                required_extensions << "citext"
              end
              if columns.any? { |column| column.data_type.start_with? "postgis" }
                required_extensions << "postgis"
              end

              required_extensions.each do |extension_name|
                extension_result = connection.exec(<<~SQL)
                  SELECT
                    (
                      SELECT 1
                      FROM pg_available_extensions
                      WHERE name = '#{extension_name}'
                    ) as is_available,
                    (
                      SELECT 1
                      FROM pg_extension
                      WHERE extname = '#{extension_name}'
                    ) as is_installed
                SQL

                row = extension_result.first
                raise MissingExtensionError, "unexpected error" if row.nil?

                unless row["is_installed"]
                  detail = if row["is_available"]
                    <<~DETAIL
                      The `#{extension_name}` extension is available for installation,
                      but has not been installed for this database.
                    DETAIL
                  else
                    <<~DETAIL
                      The `#{extension_name}` extension is not installed, and does not
                      appear to be available for installation.
                    DETAIL
                  end
                  raise MissingExtensionError, <<~ERROR.tr!("\n", " ")
                    This table uses the `#{extension_name}` data type. #{detail}
                    Add the extension, then generate and run the migrations which will
                    enable the extension for your database before defining validations
                    or triggers which rely on it.

                    Note, the `#{extension_name}` extension is required even for defining
                    some validations and triggers. This library needs to connect to postgres
                    and gererate normalized versions of validation check clauses and trigger
                    action conditions before it can even compare them to validations or triggers
                    which may or may not already exist in the database.
                  ERROR
                end
              end

              # if any of the columns require postgis
              if required_extensions.include? "postgis"
                connection.exec("SET search_path TO public,postgis;")
              end

              # note, this is not actually a TEMP TABLE, it is created within a transaction
              # and rolled back.
              connection.exec(<<~SQL)
                CREATE TABLE #{temp_table_name} (
                  #{columns_sql.join(", ")}
                );
              SQL

              temp_enums
            end
          end
        end
      end
    end
  end
end
