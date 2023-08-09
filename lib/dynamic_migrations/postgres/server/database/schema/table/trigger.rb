# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table
            # This class represents a postgres table trigger
            class Trigger < Source
              class ExpectedTableError < StandardError
              end

              class UnexpectedEventManipulationError < StandardError
              end

              class UnexpectedActionOrderError < StandardError
              end

              class UnexpectedActionStatementError < StandardError
              end

              class UnexpectedActionOrientationError < StandardError
              end

              class UnexpectedActionTimingError < StandardError
              end

              class ExpectedOldRecordsTableError < StandardError
              end

              class ExpectedNewRecordsTableError < StandardError
              end

              class ExpectedFunctionError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :event_manipulation
              attr_reader :action_timing
              attr_reader :action_order
              attr_reader :action_condition
              attr_reader :action_statement
              attr_reader :action_orientation
              attr_reader :function
              attr_reader :action_reference_old_table
              attr_reader :action_reference_new_table
              attr_reader :description

              # initialize a new object to represent a validation in a postgres table
              def initialize source, table, name, action_timing:, event_manipulation:, action_order:, action_statement:, action_orientation:, function:, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, description: nil
                super source

                unless table.is_a? Table
                  raise ExpectedTableError, table
                end
                @table = table

                unless name.is_a? Symbol
                  raise ExpectedSymbolError, name
                end
                @name = name

                unless [:before, :after].include? action_timing
                  raise UnexpectedActionTimingError, action_timing
                end
                @action_timing = action_timing

                unless [:insert, :delete, :update].include? event_manipulation
                  raise UnexpectedEventManipulationError, event_manipulation
                end
                @event_manipulation = event_manipulation

                unless action_order.is_a?(Integer) && action_order >= 1
                  raise UnexpectedActionOrderError, action_order
                end
                @action_order = action_order

                unless action_condition.nil? || action_condition.is_a?(String)
                  raise ExpectedStringError, action_condition
                end
                @action_condition = action_condition

                unless action_statement.is_a?(String) && action_statement[/\AEXECUTE FUNCTION [a-z]+(_[a-z]+)*\.[a-z]+(_[a-z]+)*\(\)\z/]
                  raise UnexpectedActionStatementError, "unexpected action statement `#{action_statement}`, currently only `EXECUTE FUNCTION function_name()` statements are supported"
                end
                @action_statement = action_statement

                unless [:row, :statement].include? action_orientation
                  raise UnexpectedActionOrientationError, action_orientation
                end
                @action_orientation = action_orientation

                unless function.is_a? Function
                  raise ExpectedFunctionError, function
                end
                # this should never happen, but adding it just in case
                unless function.source == source
                  raise "Internal error - function source `#{function.source}` does not match trigger source `#{source}`"
                end
                @function = function
                # associate this trigger with the function (so they are aware of each other)
                @function.add_trigger self

                unless action_reference_old_table.nil? || action_reference_old_table == :old_records
                  raise ExpectedOldRecordsTableError, "expected :old_records or nil, but got #{action_reference_old_table}"
                end
                @action_reference_old_table = action_reference_old_table

                unless action_reference_new_table.nil? || action_reference_new_table == :new_records
                  raise ExpectedNewRecordsTableError, "expected :new_records or nil, but got #{action_reference_new_table}"
                end
                @action_reference_new_table = action_reference_new_table

                unless description.nil?
                  raise ExpectedStringError, description unless description.is_a? String
                  @description = description
                end
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end
            end
          end
        end
      end
    end
  end
end
