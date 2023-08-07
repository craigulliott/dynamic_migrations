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
      class SchemaNameNotSetError < StandardError
      end

      class DeferrableOptionsError < StandardError
      end

      include Schema
      include CheckConstraint
      include ForeignKeyConstraint
      include ConstraintComment
      include Function
      include Trigger

      # The schema name should be set before the migrations for
      # each schema's migrations are run. This is done by:
      # DynamicMigrations::ActiveRecord::Migrators.set_schema_name :schema_name
      def self.schema_name
        @current_schema
      end

      def self.set_schema_name schema_name
        @current_schema = schema_name.to_sym
      end

      def self.clear_schema_name
        @current_schema = nil
      end

      def quote string
        connection.quote string
      end

      # this method is made available on the final migration class
      def schema_name
        sn = Migrators.schema_name
        if sn.nil?
          raise SchemaNameNotSetError
        end
        # return the schema name
        sn
      end
    end
  end
end
