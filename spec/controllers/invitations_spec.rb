RSpec.describe Controllers::Invitations do

  before do
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

    describe 'Forbidden errors' do
      describe 'When the user trying to create the invitation is not the creator of the campaign' do
        let!(:third_account) { create(:account, username: 'Third account', email: 'third@email.com') }
        let!(:second_campaign) { create(:campaign, id: 'another_campaign_id', title: 'Another long title', creator: third_account) }

        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: second_campaign.id.to_s}
        end
        it 'Returns a Forbidden (403) response code when the user creating the invitation is not the creator of the campaign' do
          expect(last_response.status).to be 403
        end
        it 'Returns the correct body when the user creating the invitation did not create the campaign' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 403,
            'field' => 'session_id',
            'error' => 'forbidden'
          })
        end
        it 'Does not create an invitation if the user creating it did not create the campaign' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
    end

    describe 'Bad Request errors' do
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
      describe 'The user is already existing in the campaign as a pending invitation' do
        let!(:invitation) { create(:invitation, status: 'pending', account: account, creator: creator, campaign: campaign) }

        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns an Bad Request (400) response code when the account already has a pending invitation' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body when the account already has a pending invitation' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'username',
            'error' => 'already_pending'
          })
        end
        it 'Does not create an invitation if the account already has a pending invitation' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 1
        end
      end
      describe 'The user is already existing in the campaign as an accepted invitation' do
        let!(:invitation) { create(:invitation, status: 'accepted', account: account, creator: creator, campaign: campaign) }

        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns an Bad Request (400) response code when the account already has an accepted invitation' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body when the account already has an accepted invitation' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 400,
            'field' => 'username',
            'error' => 'already_accepted'
          })
        end
        it 'Does not create an invitation if the account already has an accepted invitation' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 1
        end
      end
    end
  end

  describe 'GET /own' do
    let!(:session) { create(:session, account: account) }
    let!(:a_invitation) { create(:accepted_invitation, account: account, creator: creator, campaign: campaign) }
    let!(:other_campaign) { create(:campaign, id: 'another_campaign_id', title: 'another', creator: creator)}
    let!(:p_invitation) { create(:pending_invitation, id: 'another_inv_id', account: account, creator: creator, campaign: other_campaign) }

    describe 'Nominal case' do
      before do
        get '/own', {token: 'test_token', app_key: 'test_key', session_id: session.token}
      end
      it 'Returns a OK (200) status)' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(JSON.parse(last_response.body)).to eq({
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

    describe 'Nominal case' do
      describe 'when the invitation was pending' do
        let!(:invitation) { create(:pending_invitation, account: account, creator: creator, campaign: campaign) }

        before do
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted', session_id: session.token}
        end
        it 'Returns a OK (200) response code when the invitation was pending and is correctly accepted' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body when the invitation is accepted' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has correctly edited the invitation' do
          expect(Arkaan::Campaigns::Invitation.first.status).to eq :accepted
        end
      end
    end

    describe 'Alternative cases' do
      describe 'when the invitation was already accepted' do
        let!(:invitation) { create(:accepted_invitation, account: account, creator: creator, campaign: campaign) }

        before do
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted', session_id: session.token}
        end
        it 'Returns a OK (200) response code when the invitation was already accepted' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body when the invitation was already accepted' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has not edited the invitation' do
          expect(Arkaan::Campaigns::Invitation.first.status).to eq :accepted
        end
      end

      describe 'when the accepted flag is not passed and the invitation was pending' do
        let!(:invitation) { create(:pending_invitation, account: account, creator: creator, campaign: campaign) }

        before do
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', session_id: session.token}
        end
        it 'Returns a OK (200) response code when the invitation was already accepted' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body when the invitation was already accepted' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has not edited the invitation' do
          expect(Arkaan::Campaigns::Invitation.first.status).to eq :pending
        end
      end

      describe 'when the accepted flag is not passed and the invitation was accepted' do
        let!(:invitation) { create(:accepted_invitation, account: account, creator: creator, campaign: campaign) }

        before do
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', session_id: session.token}
        end
        it 'Returns a OK (200) response code when the invitation was already accepted' do
          expect(last_response.status).to be 200
        end
        it 'Returns the correct body when the invitation was already accepted' do
          expect(JSON.parse(last_response.body)).to eq({'message' => 'updated'})
        end
        it 'has not edited the invitation' do
          expect(Arkaan::Campaigns::Invitation.first.status).to eq :accepted
        end
      end
    end

    it_should_behave_like 'a route', 'put', '/invitation_id'

    describe 'Bad Request errors' do
      describe 'session_id not given error' do
        let!(:invitation) { create(:pending_invitation, account: account, creator: creator, campaign: campaign) }

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
    end

    describe 'Forbidden errors' do
      describe 'error when the user accepting the invitation is not the one it was issued to' do
        let!(:other_account) { create(:account, username: 'Babaussine', email: 'babaussine@gmail.com', id: 'another_id') }
        let!(:other_session) { create(:session, account: other_account, token: 'another_token') }
        let!(:invitation) { create(:pending_invitation, account: account, creator: creator, campaign: campaign) }

        before do
          put "/#{invitation.id.to_s}", {token: 'test_token', app_key: 'test_key', status: 'accepted', session_id: other_session.token}
        end
        it 'Returns a Forbidden (403) response code when the account accepting the invitation is not authorized to' do
          expect(last_response.status).to be 403
        end
        it 'Returns the correct body when the account accepting is not authorized to' do
          expect(JSON.parse(last_response.body)).to include_json({
            'status' => 403,
            'field' => 'session_id',
            'error' => 'forbidden'
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