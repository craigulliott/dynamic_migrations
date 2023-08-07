# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        module TriggersAndFunctionsLoader
          class EventTriggerProcedureSchemaMismatchError < StandardError
          end

          # fetch all columns from the database and build and return a
          # useful hash representing the triggers_and_functions of your database
          #
          # this query is very fast, so does not need cached (a materialized view)
          def fetch_triggers_and_functions
            rows = connection.exec(<<~SQL)
              SELECT
                n.nspname AS trigger_schema,
                t.tgname AS trigger_name,
                em.text AS event_manipulation,
                n.nspname AS event_object_schema,
                c.relname AS event_object_table,
                rank() OVER (
                  PARTITION BY (n.nspname),
                  (c.relname),
                  em.num,
                  (t.tgtype & 1),
                  (t.tgtype & 66)
                  ORDER BY
                    t.tgname
                ) AS action_order,
                CASE WHEN pg_has_role(c.relowner, 'USAGE') THEN (
                  regexp_match(
                    pg_get_triggerdef(t.oid),
                    '.{35,} WHEN ((.+)) EXECUTE FUNCTION'
                  )
                ) [1] ELSE NULL END AS action_condition,
                p_n.nspname AS function_schema,
                p.proname AS function_name,
                p.prosrc AS function_definition,
                SUBSTRING(
                  pg_get_triggerdef(t.oid)
                  FROM
                    POSITION(
                      ('EXECUTE FUNCTION') IN (
                        SUBSTRING(
                          pg_get_triggerdef(t.oid)
                          FROM
                            48
                        )
                      )
                    ) + 47
                ) AS action_statement,
                CASE t.tgtype & 1 WHEN 1 THEN 'row' ELSE 'statement' END AS action_orientation,
                CASE t.tgtype & 66 WHEN 2 THEN 'before' WHEN 64 THEN 'instead_of' ELSE 'after' END AS action_timing,
                t.tgoldtable AS action_reference_old_table,
                t.tgnewtable AS action_reference_new_table,
                obj_description(t.oid, 'pg_trigger') as description,
                obj_description(p.oid, 'pg_proc') as function_description
              FROM
                -- trigger tables
                pg_namespace n,
                pg_class c,
                pg_trigger t,
                -- procedure tables
                pg_proc p,
                pg_namespace p_n,
                (
                  VALUES
                    (4, 'insert'),
                    (8, 'delete'),
                    (16, 'update')
                ) em(num, text)
              WHERE
                n.oid = c.relnamespace
                AND c.oid = t.tgrelid
                AND p.oid = t.tgfoid
                AND p_n.oid = p.pronamespace
                AND (t.tgtype & em.num) <> 0
                AND NOT t.tgisinternal
                AND NOT pg_is_other_temp_schema(n.oid)
                AND (
                  pg_has_role(c.relowner, 'USAGE')
                  OR has_table_privilege(
                    c.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'
                  )
                  OR has_any_column_privilege(
                    c.oid, 'INSERT, UPDATE, REFERENCES'
                  )
                );
            SQL

            schemas = {}
            rows.each do |row|
              trigger_name = row["trigger_name"].to_sym
              event_object_schema = row["event_object_schema"].to_sym
              event_object_table = row["event_object_table"].to_sym

              schema = schemas[event_object_schema] ||= {}
              table = schema[event_object_table] ||= {}

              # by convention (and to simplify things) we place these all in the same schema
              unless row["trigger_schema"] == row["function_schema"] && row["function_schema"] == row["event_object_schema"]
                raise EventTriggerProcedureSchemaMismatchError, "Expected trigger, procedure and event_object to be in the same schema for trigger '#{trigger_name}'"
              end

              table[trigger_name] = {
                trigger_schema: row["trigger_schema"].to_sym,
                event_manipulation: row["event_manipulation"].to_sym,
                action_order: row["action_order"].to_i,
                action_condition: row["action_condition"],
                function_schema: row["function_schema"].to_sym,
                function_name: row["function_name"].to_sym,
                function_definition: row["function_definition"],
                action_statement: row["action_statement"],
                action_orientation: row["action_orientation"].to_sym,
                action_timing: row["action_timing"].to_sym,
                # `action_reference_old_table` and `action_reference_new_table` can be null
                action_reference_old_table: row["action_reference_old_table"]&.to_sym,
                action_reference_new_table: row["action_reference_new_table"]&.to_sym,
                description: row["description"],
                function_description: row["function_description"]
              }
            end
            schemas
          end
        end
      end
    end
  end
end
