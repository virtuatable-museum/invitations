RSpec.shared_examples 'invitation exists as a request' do
  describe 'when the invitation already exists as a request' do
    let!(:existing_invitation) { create(:invitation, status: :request, campaign: campaign, account: account) }

    describe 'created by a user' do
      before do
        post '/', {session_id: account_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Bad Request (400) status' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body' do
        invitation = get_invitations.first
        expect(last_response.body).to include_json({
          status: 400,
          field: 'username',
          error: 'already_request'
        })
      end
      it 'Does not create the invitation' do
        expect(get_invitations.all.count).to be 1
      end
    end
    describe 'created by campaign creator' do
      before do
        post '/', {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Bad Request (400) status' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body' do
        invitation = get_invitations.first
        expect(last_response.body).to include_json({
          status: 400,
          field: 'username',
          error: 'already_request'
        })
      end
      it 'Does not create the invitation' do
        expect(get_invitations.all.count).to be 1
      end
    end
  end
end