# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::Migration do
  let(:migration_class) { DynamicMigrations::Postgres::Generator::Migration }
  let(:migration) { DynamicMigrations::Postgres::Generator::Migration.new :my_schema }

  describe :class_methods do
    describe "setting up the structure templates" do
      after(:each) do
        migration_class.clear_structure_templates
      end

      it "adds to the classes structure templates (this is done from classes which extend this one when setting up the type of migration)" do
        migration_class.add_structure_template [:my_method], "my header"
        expect(migration_class.structure_templates).to eql([
          {
            methods: [:my_method],
            header_comment: <<~COMMENT.strip
              #
              # my header
              #
            COMMENT
          }
        ])
      end

      it "raises an error if the method name already exists in another structure template" do
        migration_class.add_structure_template [:my_method], "my header"
        expect {
          migration_class.add_structure_template [:my_method], "my header"
        }.to raise_error DynamicMigrations::Postgres::Generator::Migration::DuplicateStructureTemplateError
      end
    end
  end

  describe "for a migration class which accepts fragments for the method name `my_method`" do
    before(:each) do
      migration_class.add_structure_template [:my_method], "my header"
    end

    after(:each) do
      migration_class.clear_structure_templates
    end

    describe :initialize do
      it "initialies without error" do
        expect {
          DynamicMigrations::Postgres::Generator::Migration.new :my_schema
        }.not_to raise_error
      end
    end

    describe :schema_name do
      it "returns the schema_name which was set at initialization" do
        expect(migration.schema_name).to eq :my_schema
      end
    end

    describe :fragments do
      it "returns an empty array because no fragments have been added yet" do
        expect(migration.fragments).to eql []
      end

      describe "after a fragment has been added" do
        let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content" }

        before(:each) do
          migration.add_fragment fragment
        end

        it "returns the expected array of fragments" do
          expect(migration.fragments).to eql [fragment]
        end
      end
    end

    describe :add_fragment do
      let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content" }
      let(:fragment_from_different_schema) { DynamicMigrations::Postgres::Generator::Fragment.new :different_schema, :my_table, :my_method, :my_object, "my comment", "my content" }
      let(:fragment_with_invalid_method_name) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :unexpected_method, :my_object, "my comment", "my content" }

      it "adds and returns the expected fragment" do
        expect(migration.add_fragment(fragment)).to eq fragment
      end

      it "raises an error if the fragment belongs to a different schema than this migration" do
        expect {
          migration.add_fragment(fragment_from_different_schema)
        }.to raise_error DynamicMigrations::Postgres::Generator::Migration::UnexpectedSchemaError
      end

      it "raises an error if the fragment has a method name which is not supported by this migration type" do
        expect {
          migration.add_fragment(fragment_with_invalid_method_name)
        }.to raise_error DynamicMigrations::Postgres::Generator::Migration::UnexpectedMigrationMethodNameError
      end
    end

    describe :dependencies do
      it "raises an error because no fragments have been added" do
        expect {
          migration.dependencies
        }.to raise_error DynamicMigrations::Postgres::Generator::Migration::NoFragmentsError
      end

      describe "after a fragment which is not dependent on a table has been added" do
        let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content" }

        before(:each) do
          migration.add_fragment fragment
        end

        it "returns an empty array because no added fragments have a dependency" do
          expect(migration.dependencies).to eql []
        end

        describe "after a fragment which is dependent on a table has been added" do
          let(:fragment_with_dependency) {
            f = DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content"
            f.set_dependent_table :my_schema, :my_table
            f
          }

          before(:each) do
            migration.add_fragment fragment_with_dependency
          end

          it "returns the expected array of dependencies" do
            expect(migration.dependencies).to eql [{
              schema_name: :my_schema,
              table_name: :my_table
            }]
          end
        end
      end
    end

    describe :extract_fragments_with_dependency do
      describe "For a migration which has fragments" do
        let(:fragment_without_dependency) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content" }
        let(:fragment_with_dependency) {
          frag = DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content"
          frag.set_dependent_table :my_schema, :my_table
          frag
        }
        let(:fragment_with_different_dependency) {
          frag = DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content"
          frag.set_dependent_table :my_schema, :different_table
          frag
        }

        before(:each) do
          migration.add_fragment fragment_without_dependency
          migration.add_fragment fragment_with_dependency
          migration.add_fragment fragment_with_different_dependency
        end

        it "returns the fragments which have a dependency on the provided table" do
          expect(migration.extract_fragments_with_dependency(:my_schema, :my_table)).to eql [fragment_with_dependency]
        end

        it "removes the fragments which have a dependency on the provided table" do
          expect(migration.fragments).to eql [fragment_without_dependency, fragment_with_dependency, fragment_with_different_dependency]

          migration.extract_fragments_with_dependency(:my_schema, :my_table)

          expect(migration.fragments).to eql [fragment_without_dependency, fragment_with_different_dependency]
        end
      end
    end

    describe :content do
      it "raises an error because no fragments have been added" do
        expect {
          migration.content
        }.to raise_error DynamicMigrations::Postgres::Generator::Migration::NoFragmentsError
      end

      describe "after a fragment has been added" do
        let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :my_method, :my_object, "my comment", "my content" }

        before(:each) do
          migration.add_fragment fragment
        end

        it "returns the expected string of fragments" do
          expect(migration.content).to eq <<~RUBY.strip
            #
            # my header
            #
            # my comment
            my content
          RUBY
        end
      end
    end

    describe :name do
      it "raises an error because no fragments have been added" do
        expect {
          migration.dependencies
        }.to raise_error DynamicMigrations::Postgres::Generator::Migration::NoFragmentsError
      end

      describe "if a fragment which creates a schema has been added" do
        let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_schema, :my_table, :create_schema, :my_object, "my comment", "my content" }

        before(:each) do
          migration_class.add_structure_template [:create_schema], "my header"
          migration.add_fragment fragment
        end

        it "returns an appropriate name" do
          expect(migration.name).to eq :create_my_schema_schema
        end
      end
    end
  end
end
