require "rails_helper"

RSpec.describe "/openid/oauth2/token", :type => :request do
  before(:all) do
    @sso_server = 'https://example.com/'
    @login_url = "#{@sso_server}login"
    @silent_url = "#{@sso_server}/silent.html"
    @silent_error = "#{@silent_url}?error="
    @sso_system = AnoubisSsoServer::System.where(public: 'sso-test').first
    @sso_system.destroy if @sso_system
    @sso_system = AnoubisSsoServer::System.create({ title: 'Test SSO', public: 'sso-test', state: 'opened', request_uri: [@silent_url] })
    @default_params = {
      locale: 'en',
      client_id: @sso_system.public,
      redirect_uri: @silent_url,
      scope: 'openid email profile',
      code: 'test-code',
      code_verifier: '836459a8c63a3afac9a9160d78551ffa83c680a7293471549356741e',
      grant_type: 'authorization_code'
    }
    @user = AnoubisSsoServer::User.where(email: 'admin@examle.com').first
    @user = AnoubisSsoServer::User.create({ name: 'Test', surname: 'Test', email: 'admin@examle.com', password: 'password', password_confirmation: 'password' }) unless @user
    @session = {
      id: @user.id,
      uuid: @user.uuid,
      ttl: Time.now.utc.to_i + 3600,
      timeout: 3600
    }
    @session_name = SecureRandom.uuid
    @redis = Redis.new
    @redis_prefix = Rails.configuration.anoubis_redis_prefix
    @redis.set("#{@redis_prefix}:session:#{@session_name}", @session.to_json, ex: 300)
    @code_hash = {
      scope: @default_params[:scope].split(' '),
      code_challenge: 'wndobIXhSMoamTFlsVErtJ4LqSh4N9TMxY6rQ2Y04Ww',
      request_uri: @default_params[:redirect_uri],
      state: '07d21882-18b7-ddea-2fcaffdc84240101',
      client_id: @default_params[:client_id],
      original_url: "#{@sso_server}openid/oauth2/auth?locale=en&client_id=#{@default_params[:client_id]}",
      uuid: @user.uuid
    }
    @redis.set("#{@redis_prefix}:code:#{@default_params[:code]}", @code_hash.to_json, ex: 300)
  end

  after(:all) do
    @user.destroy if @user
    if @sso_system
      @sso_system.after_destroy_sso_server_system
      AnoubisSsoServer::System.where(id: @sso_system.id).delete_all
    end
    @redis.del("#{@redis_prefix}:session:#{@session_name}")
    @redis.del("#{@redis_prefix}:code:#{@default_params[:code]}")
  end

  it "hasn't parameter 'client_id'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale)#, :headers => @headers
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'client_id'))
  end

  it "hasn't correct parameter 'client_id'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale).merge({ client_id: 'test' })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'client_id'))
  end

  it "hasn't parameter 'redirect_uri'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale, :client_id)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'redirect_uri'))
  end

  it "hasn't correct parameter 'redirect_uri'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale, :client_id).merge({ redirect_uri: 'https://test.com/' })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'redirect_uri'))
  end

  it "hasn't parameter 'scope'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale, :client_id, :redirect_uri)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'scope'))
  end

  it "hasn't parameter 'code'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :scope)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'code'))
  end

  it "hasn't parameter 'code_verifier'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :scope, :code)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'code_verifier'))
  end

  it "hasn't parameter 'grant_type'" do
    post "/openid/oauth2/token", :params => @default_params.slice(:locale, :client_id, :redirect_uri, :scope, :code, :code_verifier)
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_defined', title: 'grant_type'))
  end

  it "hasn't correct parameter 'code'" do
    post "/openid/oauth2/token", :params => @default_params.merge({ code: 123 })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'code'))
  end

  it "hasn't correct parameter 'code_verifier'" do
    @redis.set("#{@redis_prefix}:code:#{@default_params[:code]}", @code_hash.to_json, ex: 300)
    cookies[:oauth_session] = @session_name
    post "/openid/oauth2/token", :params => @default_params.merge({ code_verifier: 123 })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'code_verifier'))
  end

  it "hasn't correct parameter 'redirect_uri'" do
    @redis.set("#{@redis_prefix}:code:#{@default_params[:code]}", @code_hash.to_json, ex: 300)
    cookies[:oauth_session] = @session_name
    post "/openid/oauth2/token", :params => @default_params.merge({ redirect_uri: 123 })
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:result, :message)
    expect(data[:result]).to eq(-1)
    expect(data[:message]).to eq(I18n.t('anoubis.errors.is_not_correct', title: 'redirect_uri'))
  end

  it "received token" do
    @redis.set("#{@redis_prefix}:code:#{@default_params[:code]}", @code_hash.to_json, ex: 300)
    cookies[:oauth_session] = @session_name
    post "/openid/oauth2/token", :params => @default_params
    expect(response.code).to eq "200"
    data = JSON.parse(response.body, { symbolize_names: true })
    expect(data.keys).to contain_exactly(:access_token, :expires_in, :id_token, :scope, :token_type)
  end

  it "options requested" do
    options "/openid/oauth2/token", :params => @default_params
    expect(response.code).to eq "204"
  end
end