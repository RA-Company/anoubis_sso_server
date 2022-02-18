require "rails_helper"

RSpec.describe "/openid/oauth2/auth", :type => :request do
  before(:all) do
    @silent_url = 'https://example.com/silent.html'
    @sso_system = AnoubisSsoServer::System.where(public: 'sso-test').first
    @sso_system.destroy if @sso_system
    @sso_system = AnoubisSsoServer::System.create({ title: 'Test SSO', public: 'sso-test', state: 'opened', request_uri: [@silent_url] })
  end

  after(:all) do
    if @sso_system
      @sso_system.after_destroy_sso_server_system
      AnoubisSsoServer::System.where(id: @sso_system.id).delete_all
    end
  end

  it "hasn't parameter 'client_id'" do
    get "/openid/oauth2/auth", :params => { locale: 'en' }#, :headers => @headers
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'client_id'))
  end

  it "hasn't correct parameter 'client_id'" do
    get "/openid/oauth2/auth", :params => { locale: 'en', client_id: 'test' }
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'client_id'))
  end

  it "hasn't parameter 'redirect_uri'" do
    get "/openid/oauth2/auth", :params => { locale: 'en', client_id: @sso_system.public }
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'redirect_uri'))
  end

  it "hasn't correct parameter 'redirect_uri'" do
    get "/openid/oauth2/auth", :params => { locale: 'en', client_id: @sso_system.public, redirect_uri: 'https://test.com/' }
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'redirect_uri'))
  end
end