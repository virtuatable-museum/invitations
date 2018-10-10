RSpec.describe Controllers::Invitations do

  def clean_database
    DatabaseCleaner[:mongoid, {connection: 'test'}].clean
  end

  before do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:creator) { create(:account, username: 'Creator', email: 'creator@mail.com') }
  let!(:gateway) { create(:gateway, active: true, running: true) }
  let!(:application) { create(:application, creator: account) }
  let!(:campaign) { create(:campaign, creator: creator) }
  
  let!(:decorator) { Arkaan::Decorators::Gateway.new('create', gateway) }
  let!(:query_app) { create(:application, name: 'query_app', key: 'random_key', creator: account) }

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
          expect(get_invitations.count).to be 0
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
          expect(get_invitations.count).to be 0
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
          expect(get_invitations.count).to be 0
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
          expect(get_invitations.count).to be 0
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
          expect(get_invitations.count).to be 0
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
          expect(get_invitations.count).to be 0
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
          expect(get_invitations.count).to be 0
        end
      end
    end
  end

  describe 'GET /' do

    let!(:other_account) { create(:random_account) }
    let!(:acc_campaign) { create(:random_campaign, creator: account) }
    let!(:session) { create(:random_session, account: account) }
    let!(:other_session) { create(:random_session, account: other_account) }

    describe 'Nominal cases' do
      describe 'With a pending invitation from a user to another' do
        let!(:invitation) { create(:pending_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'pending',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 0,
                  'is_private' => true
                }
              }
            ])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
      end

      describe 'With an accepted invitation from a user to another' do
        let!(:invitation) { create(:accepted_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'accepted',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 1,
                  'is_private' => true
                }
              }
            ])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
      end

      describe 'With a request invitation from a user to another' do
        let!(:invitation) { create(:request_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the requesting account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'request',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 0,
                  'is_private' => true
                }
              }
            ])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'request',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 0,
                  'is_private' => true
                }
              }
            ])
          end
        end
      end

      describe 'With a refused invitation from a user to another' do
        let!(:invitation) { create(:refused_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
      end

      describe 'With an ignored invitation from a user to another' do
        let!(:invitation) { create(:ignored_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'ignored',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 0,
                  'is_private' => true
                }
              }
            ])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
      end

      describe 'With a blocked invitation from a user to another' do
        let!(:invitation) { create(:blocked_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'request',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 0,
                  'is_private' => true
                }
              }
            ])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([
              {
                'id' => invitation.id.to_s,
                'status' => 'blocked',
                'created_at' => invitation.created_at.utc.iso8601,
                'username' => other_account.username,
                'campaign' => {
                  'id' => acc_campaign.id.to_s,
                  'title' => acc_campaign.title,
                  'description' => acc_campaign.description,
                  'creator' => account.username,
                  'tags' => [],
                  'max_players' => 5,
                  'current_players' => 0,
                  'is_private' => true
                }
              }
            ])
          end
        end
      end

      describe 'With an expelled invitation from a user to another' do
        let!(:invitation) { create(:expelled_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
      end

      describe 'With a left invitation from a user to another' do
        let!(:invitation) { create(:left_invitation, campaign: acc_campaign, account: other_account) }

        describe 'With the invited account session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
        describe 'With the campaign creator session' do
          before do
            get '/', {token: 'test_token', app_key: 'test_key', session_id: session.token}
          end
          it 'Returns a OK (200) status' do
            expect(last_response.status).to be 200
          end
          it 'Returns the correct body' do
            expect(JSON.parse(last_response.body)).to eq([])
          end
        end
      end
    end

    it_should_behave_like 'a route', 'get', '/'

    describe '400 errors' do
      describe 'session ID not given' do
        before do
          get '/', {token: 'test_token', app_key: 'test_key'}
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
          get '/', {token: 'test_token', app_key: 'test_key', session_id: 'unknown_session_id'}
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

  describe 'DELETE /:id' do
    let!(:session) { create(:session, account: account) }
    
    describe 'Nominal case' do
      include_examples 'Deletion nominal case' 
    end

    it_should_behave_like 'a route', 'put', '/invitation_id'

    describe 'Bad Request errors' do
      describe 'session_id not given error' do
        let!(:invitation) { create(:pending_invitation, account: account, campaign: campaign) }

        before do
          delete "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted'}
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
        delete '/any_unknown_id', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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