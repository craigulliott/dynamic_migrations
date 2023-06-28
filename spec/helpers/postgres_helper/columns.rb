module Helpers
  class PostgresHelper
    module Columns
      def create_column schema_name, table_name, column_name, type
        sql_type = case type
        when :integer
          "int"
        else
          raise "Unknown type #{type}"
        end

        connection.exec(<<-SQL)
          ALTER TABLE #{connection.quote_ident schema_name.to_s}.#{connection.quote_ident table_name.to_s}
            ADD COLUMN #{connection.quote_ident column_name.to_s} #{sql_type}
        SQL
      end
    end
  end
end
