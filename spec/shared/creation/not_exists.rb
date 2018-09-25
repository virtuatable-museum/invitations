RSpec.shared_examples 'invitation does not exist' do
  describe 'when the invitation does not exist yet' do
    describe 'created by a user' do
      before do
        post '/', {session_id: account_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        invitation = get_invitations.first
        expect(last_response.body).to include_json({
          message: 'created',
          item: {
            id: invitation.id.to_s,
            username: invitation.account.username
          }
        })
      end
      it 'Creates the invitation' do
        expect(get_invitations.count).to be 1
      end
      describe 'Campaign attributes' do
        let!(:created_invitation) { get_invitations.first }

        it 'Creates the invitation with the right campaign' do
          expect(created_invitation.campaign.id.to_s).to eq(campaign.id.to_s)
        end
        it 'Creates the invitation with the right account' do
          expect(created_invitation.account.id.to_s).to eq(account.id.to_s)
        end
        it 'Creates the invitation with the right status' do
          expect(created_invitation.status).to eq(:request)
        end
      end
    end
    describe 'created by campaign creator' do
      before do
        post '/', {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        invitation = get_invitations.first
        expect(last_response.body).to include_json({
          message: 'created',
          item: {
            id: invitation.id.to_s,
            username: invitation.account.username
          }
        })
      end
      it 'Creates the invitation' do
        expect(get_invitations.count).to be 1
      end
      describe 'Campaign attributes' do
        let!(:created_invitation) { get_invitations.first }

        it 'Creates the invitation with the right campaign' do
          expect(created_invitation.campaign.id.to_s).to eq(campaign.id.to_s)
        end
        it 'Creates the invitation with the right account' do
          expect(created_invitation.account.id.to_s).to eq(account.id.to_s)
        end
        it 'Creates the invitation with the right status' do
          expect(created_invitation.status).to eq(:pending)
        end
      end
    end
  end
end