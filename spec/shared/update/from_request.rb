RSpec.shared_examples 'from request' do
  let!(:request_invitation) { create(:invitation, status: :request, campaign: campaign, account: account) }

  include_examples 'from request to accepted'
  include_examples 'from request to blocked'
  include_examples 'from request to expelled'
  include_examples 'from request to ignored'
  include_examples 'from request to left'
  include_examples 'from request to request'
  include_examples 'from request to refused'
  include_examples 'from request to request'
end