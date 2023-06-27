# frozen_string_literal: true

RSpec.describe DynamicMigrations do
  it "has a version number" do
    expect(DynamicMigrations::VERSION).not_to be nil
  end
end
