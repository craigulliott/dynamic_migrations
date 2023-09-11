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

              class UnexpectedParametersError < StandardError
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

              class UnexpectedActionOrderError < StandardError
              end

              attr_reader :table
              attr_reader :name
              attr_reader :event_manipulation
              attr_reader :action_timing
              attr_reader :action_condition
              attr_reader :parameters
              attr_reader :action_orientation
              attr_reader :function
              attr_reader :action_reference_old_table
              attr_reader :action_reference_new_table
              attr_reader :description

              # initialize a new object to represent a validation in a postgres table
              def initialize source, table, name, action_timing:, event_manipulation:, parameters:, action_orientation:, function:, action_order: nil, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, description: nil
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

                if from_configuration?
                  unless action_order.nil?
                    raise UnexpectedActionOrderError, "Unexpected `action_order` argument. Action order is calculated dynamically for configured triggers."
                  end

                else
                  unless action_order.is_a?(Integer) && action_order >= 1
                    raise UnexpectedActionOrderError, "Missing valid `action_order` argument. Action order must be provided for triggers loaded from the database."
                  end
                  @action_order = action_order
                end

                unless action_condition.nil? || action_condition.is_a?(String)
                  raise ExpectedStringError, action_condition
                end
                @action_condition = action_condition&.strip

                is_comma_sperated_list_of_strings = (parameters.is_a?(String) && parameters[/\A'[\w\d_ -]+'(, ?'[\w\d_ -]+')*\z/])
                unless parameters.nil? || is_comma_sperated_list_of_strings
                  raise UnexpectedParametersError, "unexpected parameters `#{parameters}`, currently only a comma seeparated list of strings is supported"
                end
                @parameters = parameters&.strip

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
                  @description = description.strip
                  @description = nil if description == ""
                end
              end

              def action_order
                # if the source is the database, then return the locally stored
                # representation of the action order
                if from_database?
                  action_order = @action_order
                  if action_order.nil?
                    raise "Missing valid action_order. This should be impossible."
                  end
                  action_order

                # otherwise return the dynamically calculated action order, this is calculated
                # by returning this triggers index in the list of alphabetically sorted triggers
                # for this triggers table
                else
                  pos = @table.triggers.sort_by(&:name).index(self)
                  if pos.nil?
                    raise "Trigger not found in table triggers list. This should be impossible."
                  end
                  pos + 1
                end
              end

              def action_condition= new_action_condition
                unless new_action_condition.nil? || new_action_condition.is_a?(String)
                  raise ExpectedStringError, new_action_condition
                end
                @action_condition = new_action_condition&.strip
              end

              def parameters= new_parameters
                unless new_parameters.nil? || new_parameters.is_a?(String)
                  raise ExpectedStringError, new_parameters
                end
                @parameters = new_parameters&.strip
              end

              # return true if this has a description, otherwise false
              def has_description?
                !@description.nil?
              end

              def differences_descriptions other_trigger
                descriptions = method_differences_descriptions other_trigger, [
                  :event_manipulation,
                  :action_timing,
                  :action_order,
                  :action_condition,
                  :parameters,
                  :action_orientation,
                  :action_reference_old_table,
                  :action_reference_new_table
                ]
                # add the function differences descriptions
                function.differences_descriptions(other_trigger.function).each do |description|
                  descriptions << "function_#{description}"
                end
                # return the combined differences
                descriptions
              end
            end
          end
        end
      end
    end
  end
end
