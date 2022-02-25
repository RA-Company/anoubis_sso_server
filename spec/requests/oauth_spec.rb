require "rails_helper"

RSpec.describe "/openid/oauth2/auth", :type => :request do
  before(:all) do
    @login_url = 'https://example.com/login'
    @silent_url = 'https://example.com/silent.html'
    @silent_error = "#{@silent_url}?error="
    @sso_system = AnoubisSsoServer::System.where(public: 'sso-test').first
    @sso_system.destroy if @sso_system
    @sso_system = AnoubisSsoServer::System.create({ title: 'Test SSO', public: 'sso-test', state: 'opened', request_uri: [@silent_url] })
    @default_params = {
      locale: 'en',
      client_id: @sso_system.public,
      redirect_uri: @silent_url,
      response_type: 'code',
      scope: 'openid email profile',
      code_challenge: 'wndobIXhSMoamTFlsVErtJ4LqSh4N9TMxY6rQ2Y04Ww',
      code_challenge_method: 's256',
      state: '07d21882-18b7-ddea-2fcaffdc84240101',
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

  it "has empty parameter 'response_type'" do
    get "/openid/oauth2/auth", :params => @default_params.except(:prompt).merge(response_type: ' ')
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'response_type'))
  end

  it "has empty parameter 'response_type' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.merge(response_type: ' ')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_correct', title: 'response_type')))
  end

  it "hasn't parameter 'scope'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'scope'))
  end

  it "hasn't parameter 'scope' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :prompt)
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_defined', title: 'scope')))
  end

  it "hasn't parameter 'code_challenge'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :scope)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'code_challenge'))
  end

  it "hasn't parameter 'code_challenge' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :scope, :prompt)
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_defined', title: 'code_challenge')))
  end

  it "hasn't parameter 'code_challenge_method'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :code_challenge, :scope)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'code_challenge_method'))
  end

  it "hasn't parameter 'code_challenge_method' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :scope, :code_challenge, :prompt)
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_defined', title: 'code_challenge_method')))
  end

  it "hasn't parameter 'state'" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :code_challenge, :code_challenge_method, :scope)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'state'))
  end

  it "hasn't parameter 'state' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :response_type, :scope, :code_challenge, :code_challenge_method, :prompt)
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_defined', title: 'state')))
  end

  it "hasn't correct parameter 'response_type'" do
    get "/openid/oauth2/auth", :params => @default_params.except(:prompt).merge(response_type: ' 1')
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'response_type'))
  end

  it "hasn't correct parameter 'response_type' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.merge(response_type: ' 1')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_correct', title: 'response_type')))
  end

  it "hasn't correct parameter 'scope'" do
    get "/openid/oauth2/auth", :params => @default_params.except(:prompt).merge(scope: ' ')
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'scope'))
  end

  it "hasn't correct parameter 'scope' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.merge(scope: ' ')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_correct', title: 'scope')))
  end

  it "hasn't correct parameter 'code_challenge_method'" do
    get "/openid/oauth2/auth", :params => @default_params.except(:prompt).merge(code_challenge_method: 'test')
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'code_challenge_method'))
  end

  it "hasn't correct parameter 'code_challenge_method' in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.merge(code_challenge_method: 'test')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_correct', title: 'code_challenge_method')))
  end

  it "has incorrect 'state' size" do
    get "/openid/oauth2/auth", :params => @default_params.except(:prompt).merge(state: 'test')
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.less_than', title: 'state', size: 6))
  end

  it "has incorrect 'state' size in silent mode" do
    get "/openid/oauth2/auth", :params => @default_params.merge(state: 'test')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.less_than', title: 'state', size: 6)))
  end

  it "not logged in" do
    get "/openid/oauth2/auth", :params => @default_params.except(:prompt)
    expect(response.code).to eq "302"
    expect(response).to redirect_to("#{@login_url}?code=")
  end
end