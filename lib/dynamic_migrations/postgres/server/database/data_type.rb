# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    class Server
      class Database
        class DataType
          DATA_TYPES = {
            bigint: {
              description: "signed eight-byte integer"
            },
            bigserial: {
              description: "autoincrementing eight-byte integer"
            },
            bit: {
              description: "fixed-length bit string",
              args: "[ (n) ]"
            },
            "bit varying": {
              description: "variable-length bit string",
              args: "[ (n) ]"
            },
            boolean: {
              description: "logical Boolean (true/false)"
            },
            box: {
              description: "rectangular box on a plane"
            },
            bytea: {
              description: "binary data (“byte array”)"
            },
            character: {
              description: "fixed-length character string",
              args: "[ (n) ]"
            },
            "character varying": {
              description: "variable-length character string",
              args: "[ (n) ]"
            },
            cidr: {
              description: "IPv4 or IPv6 network address"
            },
            circle: {
              description: "circle on a plane"
            },
            date: {
              description: "calendar date (year, month, day)"
            },
            "double precision": {
              description: "double precision floating-point number (8 bytes)"
            },
            inet: {
              description: "IPv4 or IPv6 host address"
            },
            integer: {
              description: "signed four-byte integer"
            },
            interval: {
              description: "time span",
              args: "[ fields ] [ (p) ]"
            },
            json: {
              description: "textual JSON data"
            },
            jsonb: {
              description: "binary JSON data, decomposed"
            },
            line: {
              description: "infinite line on a plane"
            },
            lseg: {
              description: "line segment on a plane"
            },
            macaddr: {
              description: "MAC (Media Access Control) address"
            },
            macaddr8: {
              description: "MAC (Media Access Control) address (EUI-64 format)"
            },
            money: {
              description: "currency amount"
            },
            numeric: {
              description: "exact numeric of selectable precision",
              args: "[ (p, s) ]"
            },
            path: {
              description: "geometric path on a plane"
            },
            pg_lsn: {
              description: "PostgreSQL Log Sequence Number"
            },
            pg_snapshot: {
              description: "user-level transaction ID snapshot"
            },
            point: {
              description: "geometric point on a plane"
            },
            polygon: {
              description: "closed geometric path on a plane"
            },
            real: {
              description: "single precision floating-point number (4 bytes)"
            },
            smallint: {
              description: "signed two-byte"
            },
            smallserial: {
              description: "autoincrementing two-byte"
            },
            serial: {
              description: "autoincrementing four-byte"
            },
            text: {
              description: "variable-length character string"
            },
            time: {
              description: "time of day (no time zone)",
              args: "[ (p) ]"
            },
            "time with time zone": {
              description: "time of day, including time zone",
              args: "[ (p) ]"
            },
            timestamp: {
              description: "date and time (no time zone)",
              args: "[ (p) ]"
            },
            "timestamp with time zone": {
              description: "date and time, including time zone",
              args: "[ (p) ]"
            },
            tsquery: {
              description: "text search query"
            },
            tsvector: {
              description: "text search document"
            },
            txid_snapshot: {
              description: "user-level transaction ID snapshot (deprecated; see pg_snapshot)"
            },
            uuid: {
              description: "universally unique identifier"
            },
            xml: {
              description: "XML data"
            }
          }

          attr_reader :name

          def initialize name
            raise ExpectedSymbolError, name unless name.is_a? Symbol
            raise UnexpectedTypeError, name unless DATA_TYPES.key? name
            @name = name.to_sym
          end
        end
      end
    end
  end
end
