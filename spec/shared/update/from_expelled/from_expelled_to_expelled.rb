RSpec.shared_examples 'from expelled to expelled' do
  describe 'Update from expelled to expelled' do
    describe 'update by the user' do
      before do
        put "/#{expelled_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token', status: 'expelled'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'updated',
          item: {
            id: expelled_invitation.id.to_s,
            status: 'expelled'
          }
        })
      end
      it 'Has not updated the invitation' do
        expect(expelled_invitation.reload.status_expelled?).to be true
      end
    end
    describe 'update by the creator' do
      before do
        put "/#{expelled_invitation.id.to_s}", {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', status: 'expelled'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'updated',
          item: {
            id: expelled_invitation.id.to_s,
            status: 'expelled'
          }
        })
      end
      it 'Has not updated the invitation' do
        expect(expelled_invitation.reload.status_expelled?).to be true
      end
    end
  end
end