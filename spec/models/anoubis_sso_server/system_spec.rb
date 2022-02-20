require 'rails_helper'

module AnoubisSsoServer
  RSpec.describe System, type: :model do
    it "is valid" do
      expect(create(:system)).to be_valid
    end
  end
end
