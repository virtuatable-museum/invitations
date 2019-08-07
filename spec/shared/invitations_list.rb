RSpec.shared_examples 'GET /' do

  let!(:other_account) { create(:random_account) }
  let!(:acc_campaign) { create(:random_campaign, creator: account) }
  let!(:session) { create(:random_session, account: account) }
  let!(:other_session) { create(:random_session, account: other_account) }

  describe 'Nominal cases' do
    describe 'With a pending invitation from a user to another' do
      let!(:invitation) { create(:pending_invitation, campaign: acc_campaign, account: other_account) }

      describe 'With the invited account session' do
        before do
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: other_session.token}
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
          get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: session.token}
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

  it_should_behave_like 'a route', 'get', '/invitations'

  describe '400 errors' do
    describe 'session ID not given' do
      before do
        get '/invitations', {token: 'test_token', app_key: 'test_key'}
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
        get '/invitations', {token: 'test_token', app_key: 'test_key', session_id: 'unknown_session_id'}
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