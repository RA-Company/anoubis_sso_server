require "rails_helper"

RSpec.describe "/api/1/main", :type => :request do
  before(:all) do
    @login_url = 'https://example.com/login'
    @silent_url = 'https://example.com/silent.html'
    @silent_error = "#{@silent_url}?error="

    @default_params = {
      locale: 'en',
      code: SecureRandom.uuid,
      session_name: SecureRandom.uuid,
      login_code: SecureRandom.uuid
    }

    @session = {
      test: 'session'
    }

    @login_session = {
      original_url: @silent_url
    }

    @redis = Redis.new
    @redis_prefix = Rails.configuration.anoubis_redis_prefix
    @redis.set("#{@redis_prefix}:session:#{@default_params[:session_name]}", @session.to_json, ex: 300)
    @redis.set("#{@redis_prefix}:auth_code:#{@default_params[:code]}", @default_params[:login_code], ex: 300)
    @redis.set("#{@redis_prefix}:login_code:#{@default_params[:login_code]}", @login_session.to_json, ex: 300)
  end

  after(:all) do
    @redis.del("#{@redis_prefix}:session:#{@default_params[:session_name]}")
    @redis.del("#{@redis_prefix}:auth_code:#{@default_params[:code]}")
    @redis.del("#{@redis_prefix}:login_code:#{@default_params[:code]}")
  end

  it "hasn't parameter 'code'" do
    get "/api/1/auth", :params => @default_params.slice(:locale)#, :headers => @headers
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_defined', title: 'code')))
  end

  it "session was expired" do
    get "/api/1/auth", :params => @default_params.slice(:locale).merge( code: 'test')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.session_expired')))
  end

  it "hasn't correct parameter 'code'" do
    cookies[:oauth_session] = @default_params[:session_name]
    get "/api/1/auth", :params => @default_params.slice(:locale).merge( code: 'test')
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.is_not_correct', title: 'code')))
  end

  it "correct auth" do
    cookies[:oauth_session] = @default_params[:session_name]
    @redis.set("#{@redis_prefix}:auth_code:#{@default_params[:code]}", @default_params[:login_code], ex: 300)
    @redis.set("#{@redis_prefix}:login_code:#{@default_params[:login_code]}", @login_session.to_json, ex: 300)
    get "/api/1/auth", :params => @default_params.slice(:locale, :code)
    expect(response).to redirect_to(@login_session[:original_url])
  end
end