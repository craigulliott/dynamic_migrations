# frozen_string_literal: true

module DynamicMigrations
  module Postgres
    module DataTypes
      class MissingRequiredAttributeError < StandardError
        def initialize data_type, attribute
          super "Missing required attribute `#{attribute}` for data_type `#{data_type}`"
        end
      end

      class UnexpectedPropertyError < StandardError
        def initialize data_type, attribute, value
          super "Unexpected property `#{attribute}` with value `#{value}` for data_type `#{data_type}`"
        end
      end

      class UnsupportedTypeError < StandardError
        def initialize data_type
          super "Unsupported type `#{data_type}`"
        end
      end

      DATA_TYPES = {
        ARRAY: {
          description: "binary data (“byte array”)",
          required: [
            :udt_schema,
            :udt_name
          ]
        },
        "USER-DEFINED": {
          description: "binary data (“byte array”)",
          required: [
            :udt_schema,
            :udt_name
          ]
        },
        bigint: {
          description: "signed eight-byte integer",
          required: [
            :numeric_precision,
            :numeric_precision_radix,
            :numeric_scale
          ]
        },
        # skipping this, in my tests it automatically turned into a bigint
        # bigserial: {
        #   description: "autoincrementing eight-byte integer"
        # },
        bit: {
          description: "fixed-length bit string",
          args: "[ (n) ]",
          required: [
            :character_maximum_length
          ]
        },
        "bit varying": {
          description: "variable-length bit string",
          args: "[ (n) ]"
        },
        boolean: {
          description: "logical Boolean (true/false)",
          required: []
        },
        box: {
          description: "rectangular box on a plane"
        },
        bytea: {
          description: "binary data (“byte array”)"
        },
        character: {
          description: "fixed-length character string",
          args: "[ (n) ]",
          required: [
            :character_maximum_length,
            :character_octet_length
          ]
        },
        "character varying": {
          description: "variable-length character string",
          args: "[ (n) ]",
          required: [
            :character_octet_length
          ]
        },
        cidr: {
          description: "IPv4 or IPv6 network address"
        },
        circle: {
          description: "circle on a plane"
        },
        date: {
          description: "calendar date (year, month, day)",
          required: [
            :datetime_precision
          ]
        },
        "double precision": {
          description: "double precision floating-point number (8 bytes)",
          required: [
            :numeric_precision,
            :numeric_precision_radix
          ]
        },
        inet: {
          description: "IPv4 or IPv6 host address"
        },
        integer: {
          description: "signed four-byte integer",
          required: [
            :numeric_precision,
            :numeric_precision_radix,
            :numeric_scale
          ]
        },
        interval: {
          description: "time span",
          args: "[ fields ] [ (p) ]",
          required: [
            :datetime_precision
          ]
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
          args: "[ (p, s) ]",
          required: [
            :numeric_precision_radix
          ],
          optional: [
            :numeric_precision,
            :numeric_scale
          ]
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
          description: "single precision floating-point number (4 bytes)",
          required: [
            :numeric_precision,
            :numeric_precision_radix
          ]
        },
        smallint: {
          description: "signed two-byte",
          required: [
            :numeric_precision,
            :numeric_precision_radix,
            :numeric_scale
          ]
        },
        smallserial: {
          description: "autoincrementing two-byte"
        },
        serial: {
          description: "autoincrementing four-byte"
        },
        text: {
          description: "variable-length character string",
          required: [
            :character_octet_length
          ]
        },
        "time without time zone": {
          description: "time of day (no time zone)",
          args: "[ (p) ]",
          required: [
            :datetime_precision
          ]
        },
        "time with time zone": {
          description: "time of day, including time zone",
          args: "[ (p) ]",
          required: [
            :datetime_precision
          ]
        },
        "timestamp without time zone": {
          description: "date and time (no time zone)",
          args: "[ (p) ]",
          required: [
            :datetime_precision
          ]
        },
        "timestamp with time zone": {
          description: "date and time, including time zone",
          args: "[ (p) ]",
          required: [
            :datetime_precision
          ]
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

      def self.validate_type_exists! data_type
        raise ExpectedSymbolError, data_type unless data_type.is_a? Symbol
        raise UnsupportedTypeError, data_type unless DATA_TYPES.key? data_type
        true
      end

      def self.validate_column_properties! data_type, **column_options
        validate_type_exists! data_type

        required_attributes = DATA_TYPES[data_type][:required] || []
        optional_attributes = DATA_TYPES[data_type][:optional] || []
        possible_attributes = required_attributes + optional_attributes

        # assert all required attributes are present
        required_attributes.each do |attribute|
          unless column_options.key?(attribute) && !column_options[attribute].nil?
            raise MissingRequiredAttributeError.new data_type, attribute
          end
        end

        # assert no unexpected attributes are present
        column_options.each do |key, value|
          unless value.nil? || possible_attributes.include?(key)
            raise UnexpectedPropertyError.new data_type, key, value
          end
        end
        true
      end
    end
  end
end
