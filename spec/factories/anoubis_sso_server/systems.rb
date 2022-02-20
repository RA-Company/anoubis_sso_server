FactoryBot.define do
  factory :system, class: 'AnoubisSsoServer::System' do
    title { 'SSO' }
    public { 'sso-system' }
    state { 'hidden' }
  end
end
