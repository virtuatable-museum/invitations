RSpec.describe Controllers::Invitations do

  before do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:creator) { create(:account, username: 'Creator', email: 'creator@mail.com') }
  let!(:gateway) { create(:gateway) }
  let!(:application) { create(:application, creator: account) }
  let!(:campaign) { create(:campaign, creator: creator) }

  def app
    Controllers::Invitations.new
  end

  describe 'POST /' do
    let!(:session) { create(:session, account: creator) }

    describe 'Nominal case' do
      include_examples 'Creation nominal case'
    end

    it_should_behave_like 'a route', 'post', '/'

    describe 'Bad request errors' do
      describe 'The session is not given' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, campaign_id: campaign.id.to_s}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
      describe 'The username is not given' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', session_id: session.token, campaign_id: campaign.id.to_s}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
      describe 'The campaign is not given' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
      describe 'Creator and account are identical' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: creator.username, session_id: session.token, campaign_id: campaign.id.to_s}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
    end

    describe 'Not found errors' do
      describe 'Campaign not found error' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: 'any_unknown_id'}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
      describe 'Account not found error' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: 'any_unknown_name', session_id: session.token, campaign_id: campaign.id.to_s}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
      describe 'Session not found error' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: 'any_unknown_token', campaign_id: campaign.id.to_s}
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
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
    end
  end

  describe 'GET /own' do
    let!(:session) { create(:session, account: account) }
    let!(:a_invitation) { create(:accepted_invitation, account: account, campaign: campaign) }
    let!(:other_campaign) { create(:campaign, id: 'another_campaign_id', title: 'another', creator: creator)}
    let!(:p_invitation) { create(:pending_invitation, id: 'another_inv_id', account: account, campaign: other_campaign) }
    let!(:account_campaign) { create(:campaign, id: 'account_campaign_id', title: 'account campaign', creator: account, is_private: false) }
    let!(:r_invitation) { create(:request_invitation, id: 'request_id', campaign: account_campaign, account: creator) }

    describe 'Nominal case' do
      before do
        get '/own', {token: 'test_token', app_key: 'test_key', session_id: session.token}
      end
      it 'Returns a OK (200) status)' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(JSON.parse(last_response.body)).to include_json({
          'accepted' => {
            'count' => 1,
            'items' => [
              {
                'id' => a_invitation.id.to_s,
                'campaign' => {
                  'id' => campaign.id.to_s,
                  'title' => 'test_title',
                  'description' => 'A longer description of the campaign',
                  'creator' => {
                    'id' => creator.id.to_s,
                    'username' => 'Creator'
                  },
                  'is_private' => true,
                  'tags' => ['test_tag']
                }
              }
            ]
          },
          'pending' => {
            'count' => 1,
            'items' => [
              {
                'id' => p_invitation.id.to_s,
                'campaign' => {
                  'id' => other_campaign.id.to_s,
                  'title' => 'another',
                  'description' => 'A longer description of the campaign',
                  'creator' => {
                    'id' => creator.id.to_s,
                    'username' => 'Creator'
                  },
                  'is_private' => true,
                  'tags' => ['test_tag']

                }
              }
            ]
          },
          'request' => {
            'count' => 1,
            'items' => [
              {
                'id' => r_invitation.id.to_s,
                'campaign' => {
                  'id' => account_campaign.id.to_s,
                  'title' => 'account campaign',
                  'description' => 'A longer description of the campaign',
                  'creator' => {
                    'id' => account.id.to_s,
                    'username' => account.username
                  },
                  'is_private' => false,
                  'tags' => ['test_tag']
                }
              }
            ]
          }
        })
      end
    end

    it_should_behave_like 'a route', 'get', '/own'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          get '/own', {token: 'test_token', app_key: 'test_key'}
        end
        it 'Raises a Bad Request (400) error' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            'status' => 400,
            'field' => 'session_id',
            'error' => 'required'
          })
        end
      end
    end

    describe '404 errors' do
      describe 'session ID not found' do
        before do
          get '/own', {token: 'test_token', app_key: 'test_key', session_id: 'unknown_session_id'}
        end
        it 'Raises a Not Found (404)) error' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            'status' => 404,
            'field' => 'session_id',
            'error' => 'unknown'
          })
        end
      end
    end
  end

  describe 'PUT /:id' do
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
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted'}
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
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
        put '/any_unknown_id', {token: 'test_token', app_key: 'test_key', status: 'accepted', session_id: session.token}
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
end