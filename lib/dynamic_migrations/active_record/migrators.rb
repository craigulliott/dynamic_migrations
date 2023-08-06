# include this module at the top of your migration to get access to the
# custom migration methods. For example:
#
# class CreateFooBars < ActiveRecord::Migration[7.0]
#   include DynamicMigrations::ActiveRecord::Migrators
#
#   def change
#     ...
#   end
# end
#
module DynamicMigrations
  module ActiveRecord
    module Migrators
      include Schema
      include CheckConstraint
      include ForeignKeyConstraint
      include ConstraintComment
      include Function
      include Trigger

      @current_schema = nil

      def self.schema_name
        @current_schema
      end

      def self.set_schema_name schema_name
        @current_schema = schema_name.to_sym
      end

      def self.clear_schema_name
        @current_schema = nil
      end

      # the schema name is set by the EngineDatabase module
      # which is run by the migration rake tasks
      def schema_name
        EnhancedMigrations.schema_name
      end
    end
  end
end
