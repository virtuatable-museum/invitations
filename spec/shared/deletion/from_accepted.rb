RSpec.shared_examples 'delete accepted invitation' do
  describe 'when the invitation already exists accepted' do
    let!(:existing_invitation) { create(:invitation, status: :accepted, campaign: campaign, account: account) }

    describe 'deletion by a user' do
      before do
        delete "/invitations/#{existing_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token'}
      end
      it 'Returns a Bad Request (400) status' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          status: 400,
          field: 'invitation_id',
          error: 'impossible_deletion'
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
      it 'Returns a Bad Request (400) status' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          status: 400,
          field: 'invitation_id',
          error: 'impossible_deletion'
        })
      end
      it 'Does not create the invitation' do
        expect(get_invitations.count).to be 1
      end
    end
  end
end