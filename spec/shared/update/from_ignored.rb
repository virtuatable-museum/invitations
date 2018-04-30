RSpec.shared_examples 'from ignored' do
  let!(:ignored_invitation) { create(:invitation, status: :ignored, campaign: campaign, account: account) }

  include_examples 'from ignored to accepted'
  include_examples 'from ignored to blocked'
  include_examples 'from ignored to ignored'
  include_examples 'from ignored to ignored'
  include_examples 'from ignored to left'
  include_examples 'from ignored to pending'
  include_examples 'from ignored to refused'
  include_examples 'from ignored to request'
end