RSpec.shared_examples 'DELETE /:id' do
  
  let!(:session) { create(:session, account: account) }
    
  describe 'Nominal case' do
    let!(:account_session) { create(:session, account: account, token: 'other_token') }
    let!(:creator_session) { create(:session, account: creator, token: 'creator_token') }

    include_examples 'delete accepted invitation'
    include_examples 'delete blocked invitation'
    include_examples 'delete expelled invitation'
    include_examples 'delete ignored invitation'
    include_examples 'delete left invitation'
    include_examples 'delete pending invitation'
    include_examples 'delete refused invitation'
    include_examples 'delete request invitation'
  end

  it_should_behave_like 'a route', 'put', '/invitations/invitation_id'

  describe 'Bad Request errors' do
    describe 'session_id not given error' do
      let!(:invitation) { create(:pending_invitation, account: account, campaign: campaign) }

      before do
        delete "/invitations/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted'}
      end
      it 'Returns a Bad Request (400) when the session ID is not given' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body when the session ID is not given' do
        expect(JSON.parse(last_response.body)).to include_json({
          'status' => 400,
          'field' => 'session_id',
          'error' => 'required'
        })
      end
    end
  end

  describe 'Not Found errors' do
    before do
      delete '/invitations/any_unknown_id', {token: 'test_token', app_key: 'test_key', session_id: session.token}
    end
    describe 'Invitation not found error' do
      it 'Returns a Not Found (404) response code when the invitation is not found' do
        expect(last_response.status).to be 404
      end
      it 'Returns the correct body if the invitation is not found' do
        expect(JSON.parse(last_response.body)).to include_json({
          'status' => 404,
          'field' => 'invitation_id',
          'error' => 'unknown'
        })
      end
    end
  end
end