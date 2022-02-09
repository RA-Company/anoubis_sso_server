require "rails_helper"

RSpec.describe "/api/1/login", :type => :request do
  before(:all) do
    @headers = { "ACCEPT" => "application/json" }
    @silent_url = 'https://example.com/silent.html'
    @silent_error = "#{@silent_url}?error="
    @user = AnoubisSsoServer::User.where(email: 'admin@examle.com').first
    @user = AnoubisSsoServer::User.create({ name: 'Test', surname: 'Test', email: 'admin@examle.com', password: 'password', password_confirmation: 'password' }) unless @user
  end

  after(:all) do
    @user.destroy if @user
  end

  it "hasn't parameter 'login'" do
    get "/api/1/login", :params => { locale: 'en' }#, :headers => @headers
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.fields.login')))
  end

  it "hasn't parameter 'password'" do
    get "/api/1/login", :params => { login: 'admin@examle.com', locale: 'en' }
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.fields.password')))
  end

  it "incorrect login" do
    get "/api/1/login", :params => { login: 'admin1@examle.com', password: 'password', locale: 'en' }
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.incorrect_login')))
  end

  it "incorrect password" do
    get "/api/1/login", :params => { login: 'admin1@examle.com', password: 'password1', locale: 'en' }
    expect(response).to redirect_to(@silent_error + ERB::Util.url_encode(I18n.t('anoubis.errors.incorrect_login')))
  end
end