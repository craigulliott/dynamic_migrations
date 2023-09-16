# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table validation
            class Validation < Source
              class ExpectedTableError < StandardError
              end

              class ExpectedArrayOfColumnsError < StandardError
              end

              class DuplicateColumnError < StandardError
              end

              class UnexpectedTemplateError < StandardError
              end

              class UnnormalizableCheckClauseError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :check_clause
              attr_reader :deferrable
              attr_reader :initially_deferred
              attr_reader :description
              attr_reader :template

              # initialize a new object to represent a validation in a postgres table
              def initialize source, table, columns, name, check_clause, description: nil, deferrable: false, initially_deferred: false, template: nil
                super source
                raise ExpectedTableError, table unless table.is_a? Table
                @table = table

                # assert that the provided columns is an array
                unless columns.is_a?(Array) && columns.count > 0
                  raise ExpectedArrayOfColumnsError
                end

                @columns = {}
                columns.each do |column|
                  add_column column
                end

                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @name = name

                raise ExpectedStringError, check_clause unless check_clause.is_a? String
                @check_clause = check_clause.strip

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description.strip
                  @description = nil if description == ""
                end

                raise ExpectedBooleanError, deferrable unless [true, false].include?(deferrable)
                @deferrable = deferrable

                raise ExpectedBooleanError, initially_deferred unless [true, false].include?(initially_deferred)
                @initially_deferred = initially_deferred

                unless template.nil?
                  unless Generator::Validation.has_template? template
                    raise UnexpectedTemplateError, "Unrecognised template #{template}"
                  end
                  @template = template
                end
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              # return an array of this validations columns
              def columns
                @columns.values
              end

              def column_names
                @columns.keys
              end

              def differences_descriptions other_validation
                method_differences_descriptions other_validation, [
                  :normalized_check_clause,
                  :deferrable,
                  :initially_deferred
                ]
              end

              # create a temporary table in postgres to represent this validation and fetch
              # the actual normalized check constraint directly from the database
              def normalized_check_clause
                # no need to normalize check_clauses which originated from the database
                if from_database?
                  check_clause
                else
                  @normalized_check_clause ||= fetch_normalized_check_clause
                end
              end

              private

              def fetch_normalized_check_clause
                ncc = table.schema.database.with_connection do |connection|
                  # wrapped in a transaction jsut in case something here fails, because
                  # we don't want the temporary table to be persisted
                  connection.exec("BEGIN")

                  # create the temp table and add the expected columns and constraint
                  connection.exec(<<~SQL)
                    CREATE TEMP TABLE validation_normalized_check_clause_temp_table (
                      #{columns.map { |column| '"' + column.name.to_s + '" ' + column.temp_table_data_type.to_s }.join(", ")},
                      CONSTRAINT #{name} CHECK (#{check_clause})
                    );
                  SQL

                  # get the normalzed version of the constraint
                  rows = connection.exec(<<~SQL)
                    SELECT pg_get_constraintdef(pg_constraint.oid) AS check_clause
                    FROM pg_constraint
                    WHERE conrelid = 'validation_normalized_check_clause_temp_table'::regclass;
                  SQL

                  # delete the temp table and close the transaction
                  connection.exec("ROLLBACK")

                  # return the normalized check clause
                  rows.first["check_clause"]
                end

                if ncc.nil?
                  raise UnnormalizableCheckClauseError, "Failed to nomalize check clause `#{check_clause}`"
                end

                # extract the check clause from the result "CHECK(%check_clause%)"
                matches = ncc.match(/\ACHECK \((?<inner_clause>.*)\)\z/)
                if matches.nil?
                  raise UnnormalizableCheckClauseError, "Unparsable normalized check_clause #{ncc}"
                end

                matches[:inner_clause]
              end

              # used internally to set the columns from this objects initialize method
              def add_column column
                # assert that the provided dsl name is an array of Columns
                unless column.is_a? Column
                  raise ExpectedArrayOfColumnsError
                end

                # assert that the provided column exists within this validations table
                unless @table.has_column? column.name
                  raise ExpectedArrayOfColumnsError, "One or more columns do not exist in this validations table"
                end

                if @columns.key? column.name
                  raise(DuplicateColumnError, "Column #{column.name} already exists")
                end

                @columns[column.name] = column
              end
            end
          end
        end
      end
    end
  end
end
