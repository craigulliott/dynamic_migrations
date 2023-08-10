# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::SchemaMigrations::Section do
  describe :initialize do
    it "initialies without error and exposes the required getters" do
      section = DynamicMigrations::Postgres::Generator::SchemaMigrations::Section.new :my_schema, :my_table, :my_content, :my_object, "content here"
      expect(section.schema_name).to eq :my_schema
      expect(section.table_name).to eq :my_table
      expect(section.content_type).to eq :my_content
      expect(section.object_name).to eq :my_object
      expect(section.content).to eq "content here"
    end
  end
end
