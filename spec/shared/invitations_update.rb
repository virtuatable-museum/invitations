RSpec.shared_examples 'PUT /:id' do
  let!(:session) { create(:session, account: account) }

  describe 'Update cases' do
    let!(:account_session) { create(:session, account: account, token: 'other_token') }
    let!(:creator_session) { create(:session, account: creator, token: 'creator_token') }

    describe 'Updates from an accepted invitation' do
      include_examples 'from accepted'
    end
    describe 'Updates from a blocked invitation' do
      include_examples 'from blocked'
    end
    describe 'Updates from a pending invitation' do
      include_examples 'from pending'
    end
    describe 'Updates from a expelled invitation' do
      include_examples 'from expelled'
    end
    describe 'Updates from an ignored invitation' do
      include_examples 'from ignored'
    end
    describe 'Updates from a left invitation' do
      include_examples 'from left'
    end
    describe 'Updates from a refused invitation' do
      include_examples 'from refused'
    end
    describe 'Updates from a request invitation' do
      include_examples 'from request'
    end
  end

  it_should_behave_like 'a route', 'put', '/invitation_id'

  describe 'Bad Request errors' do
    describe 'session_id not given error' do
      let!(:invitation) { create(:pending_invitation, account: account, campaign: campaign) }

      before do
        put "/invitations/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted'}
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
    describe 'status not given error' do
      let!(:invitation) { create(:pending_invitation, account: account, campaign: campaign) }

      before do
        put "/invitations/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', session_id: session.token}
      end
      it 'Returns a Bad Request (400) when the session ID is not given' do
        expect(last_response.status).to be 400
      end
      it 'Returns the correct body when the session ID is not given' do
        expect(JSON.parse(last_response.body)).to include_json({
          'status' => 400,
          'field' => 'status',
          'error' => 'required'
        })
      end
    end
  end

  describe 'Not Found errors' do
    before do
      put '/invitations/any_unknown_id', {token: 'test_token', app_key: 'test_key', status: 'accepted', session_id: session.token}
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