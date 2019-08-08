RSpec.shared_examples 'POST /' do
  describe 'POST /' do
    let!(:session) { create(:session, account: creator) }

    describe 'Nominal case' do
      let!(:account_session) { create(:session, account: account, token: 'other_token') }
      let!(:creator_session) { create(:session, account: creator, token: 'creator_token') }

      include_examples 'invitation does not exist'
      include_examples 'invitation exists accepted'
      include_examples 'invitation exists blocked'
      include_examples 'invitation exists with an expelled status'
      include_examples 'invitation exists ignored'
      include_examples 'invitation exists with a left status'
      include_examples 'invitation exists pending'
      include_examples 'invitation exists refused'
      include_examples 'invitation exists as a request'
    end

    it_should_behave_like 'a route', 'post', '/invitations'

    describe 'Bad request errors' do
      describe 'The session is not given' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', username: account.username, campaign_id: campaign.id.to_s}
        end
        it 'Returns a Bad Request (400) response code when the session ID is not given' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body when the session ID is not given' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'session_id',
            'error' => 'required'
          })
        end
        it 'Does not create an invitation when the session ID is not given' do
          expect(get_invitations.count).to be 0
        end
      end
      describe 'The username is not given' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns a Bad Request (400) response code when the username is not given' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body when the username is not given' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'username',
            'error' => 'required'
          })
        end
        it 'Does not create an invitation when the username is not given' do
          expect(get_invitations.count).to be 0
        end
      end
      describe 'The campaign is not given' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token}
        end
        it 'Returns a Bad Request (400) response code when the campaign ID is not given' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body when the campaignID is not given' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'campaign_id',
            'error' => 'required'
          })
        end
        it 'Does not create an invitation when the campaign ID is not given' do
          expect(get_invitations.count).to be 0
        end
      end
      describe 'Creator and account are identical' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', username: creator.username, session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns an Bad Request (400) response code when the creator and the account are identical' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body when the creator and the account are identical' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'username',
            'error' => 'already_accepted'
          })
        end
        it 'Does not create an invitation when the account and the creator are identical' do
          expect(get_invitations.count).to be 0
        end
      end
    end

    describe 'Not found errors' do
      describe 'Campaign not found error' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: 'any_unknown_id'}
        end
        it 'Returns a Not Found (404) response code when the campaign is not found' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body when the campaign is not found' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'campaign_id',
            'error' => 'unknown'
          })
        end
        it 'Does not create an invitation when the campaign is not found' do
          expect(get_invitations.count).to be 0
        end
      end
      describe 'Account not found error' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', username: 'any_unknown_name', session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns a Not Found (404) response code when the account is not found' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body when the account is not found' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'username',
            'error' => 'unknown'
          })
        end
        it 'Does not create an invitation when the account is not found' do
          expect(get_invitations.count).to be 0
        end
      end
      describe 'Session not found error' do
        before do
          post '/invitations', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: 'any_unknown_token', campaign_id: campaign.id.to_s}
        end
        it 'Returns a Not Found (404) response code when the session is not found' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body when the session is not found' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 404,
            'field' => 'session_id',
            'error' => 'unknown'
          })
        end
        it 'Does not create an invitation when the session is not found' do
          expect(get_invitations.count).to be 0
        end
      end
    end
  end
end