require "rails_helper"

RSpec.describe "/openid/oauth2/auth", :type => :request do
  before(:all) do
    @silent_url = 'https://example.com/silent.html'
    @silent_error = "#{@silent_url}?error="
    @sso_system = AnoubisSsoServer::System.where(public: 'sso-test').first
    @sso_system.destroy if @sso_system
    @sso_system = AnoubisSsoServer::System.create({ title: 'Test SSO', public: 'sso-test', state: 'opened', request_uri: [@silent_url] })
    @default_params = {
      locale: 'en',
      client_id: @sso_system.public,
      redirect_uri: @silent_url,
      prompt: 'none'
    }
  end

  after(:all) do
    if @sso_system
      @sso_system.after_destroy_sso_server_system
      AnoubisSsoServer::System.where(id: @sso_system.id).delete_all
    end
  end

  it "hasn't parameter 'client_id'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale)#, :headers => @headers
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'client_id'))
  end

  it "hasn't correct parameter 'client_id'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale).merge({ client_id: 'test' })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'client_id'))
  end

  it "hasn't parameter 'redirect_uri'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'redirect_uri'))
  end

  it "hasn't correct parameter 'redirect_uri'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id).merge({ redirect_uri: 'https://test.com/' })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'redirect_uri'))
  end

  it "hasn't parameter 'response_type'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'response_type'))
  end

  it "hasn't parameter 'response_type' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :prompt)
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_defined', title: 'response_type')))
  end

  it "hasn't correct parameter 'response_type'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri).merge(response_type: ' ')
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'response_type'))
  end
end