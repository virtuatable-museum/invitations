RSpec.shared_examples 'Update nominal case' do
  let!(:account_session) { create(:session, account: account, token: 'other_token') }
  let!(:creator_session) { create(:session, account: creator, token: 'creator_token') }

  include_examples 'from pending'
end