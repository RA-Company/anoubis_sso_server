require "rails_helper"

RSpec.describe "/openid/.well-known/", :type => :request do
  before(:all) do
    @headers = { "ACCEPT" => "application/json" }
    @sso_system = AnoubisSsoServer::System.where(public: 'sso-test').first
    @sso_system.destroy if @sso_system
    @sso_system = AnoubisSsoServer::System.create({ title: 'Test SSO', public: 'sso-test' })
  end

  after(:all) do
    if @sso_system
      @sso_system.after_destroy_sso_server_system
      AnoubisSsoServer::System.where(id: @sso_system.id).delete_all
    end
  end

  it "openid-configuration" do
    get "/openid/.well-known/openid-configuration", :headers => @headers
    expect(response.content_type).to include("application/json")
    expect(response.status).to eq 200
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:issuer, :authorization_endpoint, :token_endpoint, :jwks_uri, :subject_types_supported, :response_types_supported, :claims_supported, :grant_types_supported,
                                         :response_modes_supported, :userinfo_endpoint, :scopes_supported, :token_endpoint_auth_methods_supported, :userinfo_signing_alg_values_supported,
                                         :id_token_signing_alg_values_supported, :request_parameter_supported, :request_uri_parameter_supported, :require_request_uri_registration,
                                         :claims_parameter_supported, :revocation_endpoint, :backchannel_logout_supported, :backchannel_logout_session_supported, :frontchannel_logout_supported,
                                         :frontchannel_logout_session_supported, :end_session_endpoint, :request_object_signing_alg_values_supported, :code_challenge_methods_supported)
  end

  it "jwks.json" do
    get "/openid/.well-known/jwks.json", :headers => @headers
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(response.status).to eq 200
    expect(data.has_key? :keys).to eq true
    key = data[:keys][0]
    expect(key[:use]).to eq('sig')
    expect(key[:kty]).to eq('RSA')
    expect(key[:kid]).to eq("public:#{@sso_system.uuid}")
  end
end