require "rails_helper"

RSpec.describe "/openid/oauth2/logout", :type => :request do
  before(:all) do
    @sso_server = 'https://example.com/'
    @login_url = "#{@sso_server}login"
  end

  it "has logout" do
    get "/openid/oauth2/logout"
    expect(response.code).to eq "302"
    expect(response).to redirect_to(@login_url)
  end
end