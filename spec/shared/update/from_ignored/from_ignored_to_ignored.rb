RSpec.shared_examples 'from ignored to ignored' do
  describe 'Update from ignored to ignored' do
    describe 'update by the user' do
      before do
        put "/#{ignored_invitation.id.to_s}", {session_id: account_session.token, app_key: 'test_key', token: 'test_token', status: 'ignored'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'updated'})
      end
      it 'Has not updated the invitation' do
        expect(ignored_invitation.reload.status_ignored?).to be true
      end
    end
    describe 'update by the creator' do
      before do
        put "/#{ignored_invitation.id.to_s}", {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', status: 'ignored'}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'updated'})
      end
      it 'Has not updated the invitation' do
        expect(ignored_invitation.reload.status_ignored?).to be true
      end
    end
  end
end