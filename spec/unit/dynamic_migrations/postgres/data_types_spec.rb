# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::DataTypes do
  let(:data_types_module) { DynamicMigrations::Postgres::DataTypes }

  describe :default_for do
    it "returns null for a valid type and attribute, but no default" do
      expect(data_types_module.default_for(:integer, :datetime_precision)).to be nil
    end

    it "returns the expected value for a valid type and attribute which has a default" do
      expect(data_types_module.default_for(:integer, :numeric_precision)).to eq 32
    end

    it "raises an error if the provided type does not exist" do
      expect {
        data_types_module.default_for(:not_a_real_type, :numeric_precision)
      }.to raise_error DynamicMigrations::Postgres::DataTypes::UnsupportedTypeError
    end

    it "raises an error if the provided attribute is not a real attribute" do
      expect {
        data_types_module.default_for(:integer, :not_a_real_attribute)
      }.to raise_error DynamicMigrations::Postgres::DataTypes::UnexpectedPropertyNameError
    end
  end

  describe :validate_type_exists! do
    it "returns true for a valid type" do
      expect(data_types_module.validate_type_exists!(:integer)).to be true
    end

    it "raises an error if the type does not exist" do
      expect {
        data_types_module.validate_type_exists! :not_a_real_type
      }.to raise_error DynamicMigrations::Postgres::DataTypes::UnsupportedTypeError
    end
  end

  describe :validate_column_properties! do
    describe "for an integer data_type" do
      it "returns true for a valid integer" do
        expect(data_types_module.validate_column_properties!(:integer, numeric_precision: 32, numeric_precision_radix: 2, numeric_scale: 0)).to be true
      end

      it "raises an error if providing an unsupported attribute for this type" do
        expect {
          data_types_module.validate_column_properties! :integer, numeric_precision: 32, numeric_precision_radix: 2, numeric_scale: 0, datetime_precision: 0
        }.to raise_error DynamicMigrations::Postgres::DataTypes::UnexpectedPropertyError
      end

      it "raises an error if skipping a required attribute for this type" do
        expect {
          data_types_module.validate_column_properties! :integer, numeric_precision: 32, numeric_precision_radix: 2
        }.to raise_error DynamicMigrations::Postgres::DataTypes::MissingRequiredAttributeError
      end
    end
  end
end
