RSpec.shared_examples 'from refused' do
  let!(:refused_invitation) { create(:invitation, status: :refused, campaign: campaign, account: account) }

  include_examples 'from refused to accepted'
  include_examples 'from refused to refused'
  include_examples 'from refused to expelled'
  include_examples 'from refused to ignored'
  include_examples 'from refused to left'
  include_examples 'from refused to pending'
  include_examples 'from refused to refused'
  include_examples 'from refused to request'
end