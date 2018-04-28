RSpec.shared_examples 'from pending' do
  let!(:pending_invitation) { create(:invitation, status: :pending, campaign: campaign, account: account) }

  include_examples 'from pending to accepted'
  include_examples 'from pending to blocked'
  include_examples 'from pending to expelled'
  include_examples 'from pending to ignored'
  include_examples 'from pending to left'
  include_examples 'from pending to pending'
  include_examples 'from pending to refused'
  include_examples 'from pending to request'
end