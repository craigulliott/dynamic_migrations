# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::Fragment do
  let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :add_index, :my_object, "my comment", "my content" }

  describe :initialize do
    it "initialies without error" do
      expect {
        DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :add_index, :my_object, "my comment", "my content"
      }.not_to raise_error
    end
  end

  describe :schema_name do
    it "returns the schema_name which was set at initialization" do
      expect(fragment.schema_name).to eq :my_schema
    end
  end

  describe :table_name do
    it "returns the table_name which was set at initialization" do
      expect(fragment.table_name).to eq :my_table
    end
  end

  describe :migration_method do
    it "returns the migration_method which was set at initialization" do
      expect(fragment.migration_method).to eq :add_index
    end
  end

  describe :object_name do
    it "returns the object_name which was set at initialization" do
      expect(fragment.object_name).to eq :my_object
    end
  end

  describe :dependency_schema_name do
    it "returns nil, because a dependency has not been added" do
      expect(fragment.dependency_schema_name).to eq nil
    end

    describe "after a dependency has been added" do
      before(:each) do
        fragment.set_dependent_table :dependent_schema, :dependent_table
      end

      it "returns the expected dependency_schema_name" do
        expect(fragment.dependency_schema_name).to eq :dependent_schema
      end
    end
  end

  describe :dependency_table_name do
    it "returns nil, because a dependency has not been added" do
      expect(fragment.dependency_table_name).to be_nil
    end

    describe "after a dependency has been added" do
      before(:each) do
        fragment.set_dependent_table :dependent_schema, :dependent_table
      end

      it "returns the expected dependency_table_name" do
        expect(fragment.dependency_table_name).to eq :dependent_table
      end
    end
  end

  describe :to_s do
    it "returns the finalized content from the fragment which was set at initialization (combining the comment and the content)" do
      expect(fragment.to_s).to eq <<~CONTENT.strip
        # my comment
        my content
      CONTENT
    end
  end

  describe :has_code_comment? do
    it "returns true because a code comment was provided at initialization" do
      expect(fragment.has_code_comment?).to be true
    end

    describe "when a code comment is not provided at initialization" do
      let(:comment_fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :add_index, :my_object, nil, "my content" }
      it "returns false" do
        expect(comment_fragment.has_code_comment?).to be false
      end
    end
  end

  describe :dependency do
    it "returns nil, because a dependency has not been added" do
      expect(fragment.dependency).to be_nil
    end

    describe "after a dependency has been added" do
      before(:each) do
        fragment.set_dependent_table :dependent_schema, :dependent_table
      end

      it "returns the expected dependency" do
        expect(fragment.dependency).to eql({
          schema_name: :dependent_schema,
          table_name: :dependent_table
        })
      end
    end
  end

  describe :is_dependent_on? do
    it "returns false, because a dependency has not been added" do
      expect(fragment.is_dependent_on?(:dependent_schema, :dependent_table)).to be false
    end

    describe "after a dependency has been added" do
      before(:each) do
        fragment.set_dependent_table :dependent_schema, :dependent_table
      end

      it "returns true if the provided schema_name and table_name matches the fragments dependency" do
        expect(fragment.is_dependent_on?(:dependent_schema, :dependent_table)).to be true
      end

      it "returns false if the provided schema_name and table_name does not matche the fragments dependency" do
        expect(fragment.is_dependent_on?(:another_schema, :another_table)).to be false
      end
    end
  end

  describe :set_dependent_table do
    it "sets the dependent_schema and dependent_table" do
      fragment.set_dependent_table :dependent_schema, :dependent_table

      expect(fragment.dependency_schema_name).to eq :dependent_schema
      expect(fragment.dependency_table_name).to eq :dependent_table
    end
  end
end
