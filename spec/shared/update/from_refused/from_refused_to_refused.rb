RSpec.shared_examples 'from refused to refused' do
  describe 'Update from refused to refused' do
    describe 'update by the user' do
      before do
        put "/#{refused_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token', status: 'refused'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'updated',
          item: {
            id: refused_invitation.id.to_s,
            status: 'refused'
          }
        })
      end
      it 'Has not updated the invitation' do
        expect(refused_invitation.reload.status_refused?).to be true
      end
    end
    describe 'update by the creator' do
      before do
        put "/#{refused_invitation.id.to_s}", {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', status: 'refused'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({
          message: 'updated',
          item: {
            id: refused_invitation.id.to_s,
            status: 'refused'
          }
        })
      end
      it 'Has not updated the invitation' do
        expect(refused_invitation.reload.status_refused?).to be true
      end
    end
  end
end