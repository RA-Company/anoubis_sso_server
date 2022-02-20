FactoryBot.define do
  factory :user, class: 'AnoubisSsoServer::User' do
    name { 'Test' }
    surname { 'Test' }
    email { 'test@test.com' }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
