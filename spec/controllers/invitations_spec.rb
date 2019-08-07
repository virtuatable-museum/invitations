RSpec.describe Controllers::Invitations do

  before :each do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:creator) { create(:account, username: 'Creator', email: 'creator@mail.com') }
  let!(:gateway) { create(:gateway, active: true, running: true) }
  let!(:application) { create(:application, creator: account) }
  let!(:campaign) { create(:campaign, creator: creator) }
  let!(:decorator) { Arkaan::Decorators::Gateway.new('create', gateway) }
  let!(:query_app) { create(:application, name: 'query_app', key: 'random_key', creator: account) }

  def app
    Controllers::Invitations.new
  end

  # rspec spec/controllers/invitations_spec.rb[1:1]
  include_examples 'POST /'
  # rspec spec/controllers/invitations_spec.rb[1:2]
  include_examples 'GET /'
  # rspec spec/controllers/invitations_spec.rb[1:3]
  include_examples 'PUT /:id'
  # rspec spec/controllers/invitations_spec.rb[1:4]
  include_examples 'DELETE /:id'
end