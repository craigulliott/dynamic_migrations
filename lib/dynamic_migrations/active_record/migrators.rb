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

      class MissingFunctionBlockError < StandardError
      end

      include Validation
      include ForeignKeyConstraint
      include Table
      include Index
      include Column
      include Function
      include UniqueConstraint
      include Trigger
      include Enum
      include PrimaryKey

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # The schema name should be set on the migration class before the migration
        # is run
        def schema_name
          @current_schema
        end

        def set_schema_name schema_name
          @current_schema = schema_name.to_sym
        end

        def clear_schema_name
          @current_schema = nil
        end
      end

      def quote string
        connection.quote string
      end

      # this method is made available on the final migration class
      def schema_name
        sn = self.class.schema_name
        if sn.nil?
          raise SchemaNameNotSetError
        end
        # return the schema name
        sn
      end
    end
  end
end
