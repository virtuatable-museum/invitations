RSpec.shared_examples 'from blocked' do
  let!(:blocked_invitation) { create(:invitation, status: :blocked, campaign: campaign, account: account) }

  include_examples 'from blocked to accepted'
  include_examples 'from blocked to blocked'
  include_examples 'from blocked to expelled'
  include_examples 'from blocked to ignored'
  include_examples 'from blocked to left'
  include_examples 'from blocked to pending'
  include_examples 'from blocked to refused'
  include_examples 'from blocked to request'
end