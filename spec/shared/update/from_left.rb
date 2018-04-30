RSpec.shared_examples 'from left' do
  let!(:left_invitation) { create(:invitation, status: :left, campaign: campaign, account: account) }

  include_examples 'from left to accepted'
  include_examples 'from left to blocked'
  include_examples 'from left to left'
  include_examples 'from left to ignored'
  include_examples 'from left to left'
  include_examples 'from left to pending'
  include_examples 'from left to refused'
  include_examples 'from left to request'
end