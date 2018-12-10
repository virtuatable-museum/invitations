RSpec.shared_examples 'invitation exists ignored' do
  describe 'when the invitation already exists ignored' do
    let!(:existing_invitation) { create(:invitation, status: :ignored, campaign: campaign, account: account) }

    describe 'created by a user' do
      before do
        post '/invitations', {session_id: account_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Created (201) status' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        invitation = get_invitations.first
        expect(last_response.body).to include_json({message: 'created'})
      end
      it 'Does not create a new invitation' do
        expect(get_invitations.all.count).to be 1
      end
      it 'has correctly updated the invitation status' do
        expect(get_invitations.first.status).to eq :request
      end
    end
    describe 'created by campaign creator' do
      before do
        post '/invitations', {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Forbidden (403) status' do
        expect(last_response.status).to be 403
      end
      it 'Returns the correct body' do
        invitation = get_invitations.first
        expect(last_response.body).to include_json({
          status: 403,
          field: 'username',
          error: 'ignored'
        })
      end
      it 'Does not create a new invitation' do
        expect(get_invitations.all.count).to be 1
      end
      it 'has correctly updated the invitation status' do
        expect(get_invitations.first.status).to eq :ignored
      end
    end
  end
end