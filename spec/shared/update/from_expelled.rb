RSpec.shared_examples 'from expelled' do
  let!(:expelled_invitation) { create(:invitation, status: :expelled, campaign: campaign, account: account) }

  include_examples 'from expelled to accepted'
  include_examples 'from expelled to blocked'
  include_examples 'from expelled to expelled'
  include_examples 'from expelled to ignored'
  include_examples 'from expelled to left'
  include_examples 'from expelled to pending'
  include_examples 'from expelled to refused'
  include_examples 'from expelled to request'
end