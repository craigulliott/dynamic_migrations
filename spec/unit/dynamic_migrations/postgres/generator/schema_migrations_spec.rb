# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::SchemaMigrations do
  let(:schema_migration) { DynamicMigrations::Postgres::Generator::SchemaMigrations.new }

  describe :initialize do
    it "initializes without error" do
      expect {
        DynamicMigrations::Postgres::Generator::SchemaMigrations.new
      }.not_to raise_error
    end
  end

  describe :add_content do
    it "adds content to the current migration section" do
      schema_migration.add_content :my_schema, :my_table, :my_content, :my_object, "content here"
      expect(schema_migration.current_migration_sections.count).to eq 1
      expect(schema_migration.current_migration_sections.first.schema_name).to eq :my_schema
    end
  end

  describe :finalize do
    it "does nothing if there is no current migration section" do
      schema_migration.finalize
      expect(schema_migration.to_a).to eql []
    end

    describe "after content has been added" do
      before(:each) do
        schema_migration.add_content :my_schema, :my_table, :my_content, :my_object, "content here"
      end

      it "commits the current migration to the list of final migrations" do
        schema_migration.finalize
        expect(schema_migration.to_a).to eql [{
          name: :changes_for_my_table,
          content: "content here"
        }]
      end
    end
  end

  describe :to_a do
    it "returns an empty array if no migrations has been finalized" do
      expect(schema_migration.to_a).to eql []
    end

    describe "after content has been added and finalized" do
      before(:each) do
        schema_migration.add_content :my_schema, :my_table, :my_content, :my_object, "content here"
        schema_migration.finalize
      end

      it "commits the current migration to the list of final migrations" do
        expect(schema_migration.to_a).to eql [{
          name: :changes_for_my_table,
          content: "content here"
        }]
      end
    end
  end
end
