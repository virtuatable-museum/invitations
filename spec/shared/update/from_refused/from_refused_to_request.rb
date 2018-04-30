RSpec.shared_examples 'from refused to request' do
  describe 'Update from refused to request' do
    describe 'update by the user' do
      before do
        put "/#{refused_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token', status: 'request'}
      end
      it 'Returns a Bad Request (400) status' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          status: 400,
          field: 'status',
          error: 'use_creation'
        })
      end
      it 'Has not updated the invitation' do
        expect(refused_invitation.reload.status_refused?).to be true
      end
    end
    describe 'update by the creator' do
      before do
        put "/#{refused_invitation.id.to_s}", {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', status: 'request'}
      end
      it 'Returns a Bad Request (400) status' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          status: 400,
          field: 'status',
          error: 'use_creation'
        })
      end
      it 'Has not updated the invitation' do
        expect(refused_invitation.reload.status_refused?).to be true
      end
    end
  end
end