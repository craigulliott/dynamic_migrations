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

              class UnexpectedTemplateError < StandardError
              end

              class UnnormalizableActionConditionError < StandardError
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
              attr_reader :template

              # initialize a new object to represent a trigger in a postgres table
              def initialize source, table, name, action_timing:, event_manipulation:, parameters:, action_orientation:, function:, action_order: nil, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, description: nil, template: nil
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

                unless parameters.is_a?(Array) && parameters.all? { |p| p.is_a? String }
                  raise UnexpectedParametersError, "unexpected parameters `#{parameters}`, currently only an array of strings is supported"
                end
                @parameters = parameters

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

                unless template.nil?
                  unless Generator::Trigger.has_template? template
                    raise UnexpectedTemplateError, template
                  end
                  @template = template
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

                # otherwise is is computed by finding the index of the trigger within a list of
                # triggers that are alphabetically sorted, all of which pertain to the same event
                # manipulation (such as update, insert, etc.) for this triggers table
                else
                  pos = @table.triggers.select { |t| t.event_manipulation == event_manipulation }.sort_by(&:name).index(self)
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

              def add_parameter new_parameter
                unless new_parameter.is_a? String
                  raise UnexpectedParametersError, "unexpected parameter `#{new_parameter}`, can only add strings to the list of parameters"
                end

                @parameters << new_parameter
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
                  :normalized_action_condition,
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

              # create a temporary table in postgres to represent this trigger and fetch
              # the actual normalized action_condition directly from the database
              def normalized_action_condition
                if action_condition.nil?
                  nil
                # no need to normalize action_conditions which originated from the database
                elsif from_database?
                  action_condition
                else
                  ac = table.schema.database.with_connection do |connection|
                    # wrapped in a transaction just in case something here fails, because
                    # we don't want the function, temporary table or trigger to be persisted
                    connection.exec("BEGIN")

                    # create the temp table and add the expected columns
                    temp_enums = table.create_temp_table(connection, "trigger_normalized_action_condition_temp_table")

                    # create a temporary function to trigger (triggers require a function)
                    connection.exec(<<~SQL)
                      CREATE OR REPLACE FUNCTION trigger_normalized_action_condition_temp_fn() returns trigger language plpgsql AS
                      $$ BEGIN END $$;
                    SQL

                    temp_action_condition = action_condition
                    # string replace any real enum names with their temp enum names
                    temp_enums.each do |temp_enum_name, enum|
                      temp_action_condition.gsub!("::#{enum.name}", "::#{temp_enum_name}")
                      temp_action_condition.gsub!("::#{enum.full_name}", "::#{temp_enum_name}")
                    end

                    # create a temporary trigger, from which we will fetch the normalized action condition
                    connection.exec(<<~SQL)
                      CREATE TRIGGER trigger_normalized_action_condition_temp_trigger
                      BEFORE UPDATE ON trigger_normalized_action_condition_temp_table
                        FOR EACH ROW
                          WHEN (#{action_condition})
                          EXECUTE FUNCTION trigger_normalized_action_condition_temp_fn();
                    SQL

                    # get the normalzed version of the action condition
                    rows = connection.exec(<<~SQL)
                      SELECT (
                        regexp_match(
                          pg_get_triggerdef(oid),
                          '.{35,} WHEN ((.+)) EXECUTE FUNCTION')
                        )[1] as action_condition
                      FROM pg_trigger
                      WHERE tgname = 'trigger_normalized_action_condition_temp_trigger'
                      ;
                    SQL

                    # delete the temp table and close the transaction
                    connection.exec("ROLLBACK")

                    # return the normalized action condition
                    action_condition_result = rows.first["action_condition"]

                    # string replace any enum names with their real enum names
                    temp_enums.each do |temp_enum_name, enum|
                      real_enum_name = (enum.schema == table.schema) ? enum.name : enum.full_name
                      action_condition_result.gsub!("::#{temp_enum_name}", "::#{real_enum_name}")
                    end

                    action_condition_result
                  end

                  if ac.nil?
                    raise UnnormalizableActionConditionError, "Failed to nomalize action condition `#{action_condition}`"
                  end

                  ac
                end
              end
            end
          end
        end
      end
    end
  end
end
