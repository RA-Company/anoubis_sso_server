require 'rails_helper'

module AnoubisSsoServer
  RSpec.describe MainController, type: :controller do
    context "when request sets accept => application/json" do
      it "hasn't parameter 'login' " do
        request.accept = "application/json"
        get :login, params: { use_route: 'api/1' }
        data = JSON.parse(response.body, { symbolize_names: true })
        expect(response.status).to eq 200
      end
    end
  end
end