require 'rails_helper'

RSpec.describe 'Routes', type: :routing do
  it "GET route /api/1/login" do
    expect(get: '/api/1/login').to route_to( controller: 'anoubis_sso_server/main', action: 'login', version: '1', format: 'json')
  end

  it "GET route /openid/.well-known/openid-configuration" do
    expect(get: '/openid/.well-known/openid-configuration').to route_to( controller: 'anoubis_sso_server/open_id', action: 'configuration', format: 'json')
  end

  it "GET route /openid/.well-known/jwks.json" do
    expect(get: '/openid/.well-known/jwks.json').to route_to( controller: 'anoubis_sso_server/open_id', action: 'jwks', format: 'json')
  end
end