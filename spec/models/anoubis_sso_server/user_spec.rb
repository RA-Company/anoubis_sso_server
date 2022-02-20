require 'rails_helper'

module AnoubisSsoServer
  RSpec.describe User, type: :model do
    it "is valid" do
      expect(create(:user)).to be_valid
    end
  end
end
