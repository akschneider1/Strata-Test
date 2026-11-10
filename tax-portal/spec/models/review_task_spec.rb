require 'rails_helper'

RSpec.describe ReviewTask, type: :model do
  describe "inheritance" do
    it "inherits from Strata::Task" do
      expect(described_class.superclass).to eq(Strata::Task)
    end
  end
  
  describe "creation" do
    let(:test_case) { create(:test_case) }
    
    it "can be created with valid attributes" do
      task = test_case.create_task(described_class)
      expect(task).to be_valid
    end
  end
end
