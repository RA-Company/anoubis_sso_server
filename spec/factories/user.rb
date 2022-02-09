FactoryBot.define do
  factory :user, class: 'AnoubisSsoServer::User' do
    name { 'Test' }
    surname { 'Test' }
    email { 'admin@example.com' }
    password { 'password' }
    password_confirmation { 'password' }
  end
end