FactoryGirl.define do
  factory :empty_account, class: Arkaan::Account do
    factory :account do
      username 'Babausse'
      password 'password'
      password_confirmation 'password'
      email 'machin@test.com'
      lastname 'Courtois'
      firstname 'Vincent'
    end

    factory :random_account do
      username Faker::Name.name
      password 'password'
      password_confirmation 'password'
      email Faker::Internet.email
      firstname Faker::Name.first_name
      lastname Faker::Name.last_name
    end
  end
end