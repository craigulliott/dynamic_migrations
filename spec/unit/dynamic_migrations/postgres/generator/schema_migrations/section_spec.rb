# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::SchemaMigrations::Section do
  let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_object, "my comment", "my content" }
  let(:section) { DynamicMigrations::Postgres::Generator::SchemaMigrations::Section.new :my_schema, :my_table, :the_content_type, fragment }

  describe :initialize do
    it "initialies without error" do
      expect {
        DynamicMigrations::Postgres::Generator::SchemaMigrations::Section.new :my_schema, :my_table, :my_content, fragment
      }.not_to raise_error
    end
  end

  describe :schema_name do
    it "returns the schema_name which was set at initialization" do
      expect(section.schema_name).to eq :my_schema
    end
  end

  describe :table_name do
    it "returns the table_name which was set at initialization" do
      expect(section.table_name).to eq :my_table
    end
  end

  describe :content_type do
    it "returns the content_type which was set at initialization" do
      expect(section.content_type).to eq :the_content_type
    end
  end

  describe :fragment do
    it "returns the fragment which was set at initialization" do
      expect(section.fragment).to eq fragment
    end
  end

  describe :object_name do
    it "returns the object_name from the fragment which was set at initialization" do
      expect(section.object_name).to eq :my_object
    end
  end

  describe :to_s do
    it "returns the finalized content from the fragment which was set at initialization (combining the comment and the content)" do
      expect(section.to_s).to eq <<~CONTENT.strip
        # my comment
        my content
      CONTENT
    end
  end

  describe :is_comment? do
    it "returns false because the content type provided at initialization was not :comment" do
      expect(section.is_comment?).to be false
    end

    describe "when the content type provided at initialization was :comment" do
      let(:comment_section) { DynamicMigrations::Postgres::Generator::SchemaMigrations::Section.new :my_schema, :my_table, :comment, fragment }
      it "returns true" do
        expect(comment_section.is_comment?).to be true
      end
    end
  end

  describe :content_type? do
    it "returns true if the content provided matches the content provided at initialization" do
      expect(section.content_type?(:the_content_type)).to be true
    end

    it "returns false if the content provided does not match the content provided at initialization" do
      expect(section.content_type?(:another_content_type)).to be false
    end
  end
end
