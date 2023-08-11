# frozen_string_literal: true

RSpec.describe DynamicMigrations::Postgres::Generator::Fragment do
  let(:fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_object, "my comment", "my content" }

  describe :initialize do
    it "initialies without error" do
      expect {
        DynamicMigrations::Postgres::Generator::Fragment.new :my_object, "my comment", "my content"
      }.not_to raise_error
    end
  end

  describe :object_name do
    it "returns the object_name which was set at initialization" do
      expect(fragment.object_name).to eq :my_object
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
      let(:comment_fragment) { DynamicMigrations::Postgres::Generator::Fragment.new :my_object, nil, "my content" }
      it "returns false" do
        expect(comment_fragment.has_code_comment?).to be false
      end
    end
  end
end
