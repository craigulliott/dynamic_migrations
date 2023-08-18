# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class Schema
          class Table < Source
            # This module has all the tables methods for working with triggers
            module Triggers
              class TriggerDoesNotExistError < StandardError
              end

              class TriggerAlreadyExistsError < StandardError
              end

              # returns the trigger object for the provided trigger name, and raises an
              # error if the trigger does not exist
              def trigger name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                raise TriggerDoesNotExistError unless has_trigger? name
                @triggers[name]
              end

              # returns true if this table has a trigger with the provided name, otherwise false
              def has_trigger? name
                raise ExpectedSymbolError, name unless name.is_a? Symbol
                @triggers.key? name
              end

              # returns an array of this tables triggers
              def triggers
                @triggers.values
              end

              def triggers_hash
                @triggers
              end

              # adds a new trigger to this table, and returns it
              def add_trigger name, action_timing:, event_manipulation:, parameters:, action_orientation:, function:, action_order: nil, action_condition: nil, action_reference_old_table: nil, action_reference_new_table: nil, description: nil
                if has_trigger? name
                  raise(TriggerAlreadyExistsError, "Trigger #{name} already exists")
                end
                included_target = self
                if included_target.is_a? Table
                  new_trigger = @triggers[name] = Trigger.new source, included_target, name, action_timing: action_timing, event_manipulation: event_manipulation, action_order: action_order, parameters: parameters, action_orientation: action_orientation, function: function, action_condition: action_condition, action_reference_old_table: action_reference_old_table, action_reference_new_table: action_reference_new_table, description: description
                else
                  raise ModuleIncludedIntoUnexpectedTargetError, included_target
                end
                # sort the hash so that the triggers are in alphabetical order by name
                sorted_triggers = {}
                @triggers.keys.sort.each do |name|
                  sorted_triggers[name] = @triggers[name]
                end
                @triggers = sorted_triggers
                # return the new trigger
                new_trigger
              end
            end
          end
        end
      end
    end
  end
end
