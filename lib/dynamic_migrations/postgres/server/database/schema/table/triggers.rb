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
              def add_trigger name, **trigger_options
                if has_trigger? name
                  raise(TriggerAlreadyExistsError, "Trigger #{name} already exists")
                end
                included_target = self
                if included_target.is_a? Table
                  new_trigger = @triggers[name] = Trigger.new source, included_target, name, **trigger_options
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
