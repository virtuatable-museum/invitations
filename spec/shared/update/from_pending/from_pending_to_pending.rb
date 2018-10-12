RSpec.shared_examples 'from pending to pending' do
  describe 'Update from pending to pending' do
    describe 'update by the user' do
      before do
        put "/#{pending_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token', status: 'pending'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'updated',
          item: {
            id: pending_invitation.id.to_s,
            status: 'pending'
          }
        })
      end
      it 'Has not updated the invitation' do
        expect(pending_invitation.reload.status_pending?).to be true
      end
    end
    describe 'update by the creator' do
      before do
        put "/#{pending_invitation.id.to_s}", {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', status: 'pending'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'updated',
          item: {
            id: pending_invitation.id.to_s,
            status: 'pending'
          }
        })
      end
      it 'Has not updated the invitation' do
        expect(pending_invitation.reload.status_pending?).to be true
      end
    end
  end
end