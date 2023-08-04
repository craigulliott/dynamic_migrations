module DynamicMigrations
  module NameHelper
    # shortens a table name like 'invoice_subscription_prepayments' to 'inv_sub_pre'
    warn "no unit tests"
    def abbreviate_table_name table_name
      table_name_without_schema = table_name.to_s.split(".").last
      table_name_without_schema.split("_").map { |v| v[0..2] }.join("_")
    end
  end
end
