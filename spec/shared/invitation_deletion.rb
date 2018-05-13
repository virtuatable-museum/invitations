RSpec.shared_examples 'Deletion nominal case' do
  let!(:account_session) { create(:session, account: account, token: 'other_token') }
  let!(:creator_session) { create(:session, account: creator, token: 'creator_token') }

  include_examples 'delete accepted invitation'

  include_examples 'delete blocked invitation'

  include_examples 'delete expelled invitation'

  include_examples 'delete ignored invitation'

  include_examples 'delete left invitation'

  include_examples 'delete pending invitation'

  include_examples 'delete refused invitation'

  include_examples 'delete request invitation'
end