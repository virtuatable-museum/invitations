RSpec.shared_examples 'from accepted' do
  let!(:accepted_invitation) { create(:invitation, status: :accepted, campaign: campaign, account: account, id: 'accepted_invitation') }

  include_examples 'from accepted to accepted'
  include_examples 'from accepted to blocked'
  include_examples 'from accepted to expelled'
  include_examples 'from accepted to ignored'
  include_examples 'from accepted to left'
  include_examples 'from accepted to pending'
  include_examples 'from accepted to refused'
  include_examples 'from accepted to request'
end