RSpec.shared_examples 'Creation nominal case' do
  let!(:account_session) { create(:session, account: account, token: 'other_token') }
  let!(:creator_session) { create(:session, account: creator, token: 'creator_token') }

  include_examples 'invitation does not exist'

  include_examples 'invitation exists accepted'

  include_examples 'invitation exists blocked'

  include_examples 'invitation exists with an expelled status'

  include_examples 'invitation exists ignored'

  include_examples 'invitation exists with a left status'

  include_examples 'invitation exists pending'

  include_examples 'invitation exists refused'

  include_examples 'invitation exists as a request'
end