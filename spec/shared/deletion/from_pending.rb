RSpec.shared_examples 'delete pending invitation' do
  describe 'when the invitation already exists pending' do
    let!(:existing_invitation) { create(:invitation, status: :pending, campaign: campaign, account: account) }

    describe 'deletion by a user' do
      before do
        delete "/invitations/#{existing_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token'}
      end
      it 'Returns a Forbidden (403) status' do
        expect(last_response.status).to be 403
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          status: 403,
          field: 'session_id',
          error: 'forbidden'
        })
      end
      it 'Does not create the invitation' do
        expect(get_invitations.count).to be 1
      end
    end
    describe 'deletion by campaign creator' do
      before do
        delete "/invitations/#{existing_invitation.id.to_s}", {session_id: creator_session.token, app_key: 'test_key', token: 'test_token'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'deleted'})
      end
      it 'Does not create the invitation' do
        expect(get_invitations.count).to be 0
      end
    end
  end
end