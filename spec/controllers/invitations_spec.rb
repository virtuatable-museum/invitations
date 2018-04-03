RSpec.describe Controllers::Invitations do

  before do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:creator) { create(:account, username: 'Creator', email: 'creator@mail.com') }
  let!(:gateway) { create(:gateway) }
  let!(:application) { create(:application, creator: account) }

  def app
    Controllers::Invitations.new
  end

  describe 'POST /' do

    let!(:campaign) { create(:campaign, creator: creator) }
    let!(:session) { create(:session, account: creator) }

    describe 'Nominal case' do
      before do
        post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Created (201) response code when the invitation is correctly created' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body when the invitation is created' do
        expect(JSON.parse(last_response.body)).to eq({'message' => 'created'})
      end
      it 'Creates the invitation when all parameters are correctly given' do
        expect(Arkaan::Campaigns::Invitation.all.count).to be 1
      end
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'missing.session_id'})
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'missing.username'})
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'missing.campaign_id'})
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'campaign_not_found'})
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'account_not_found'})
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'session_not_found'})
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
          expect(JSON.parse(last_response.body)).to eq({'message' => 'not_authorized'})
        end
        it 'Does not create an invitation if the user creating it did not create the campaign' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
    end

    describe 'Unprocessable entity errors' do
      describe 'Creator and account are identical' do
        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: creator.username, session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns an Unprocessable Entity (422) response code when the creator and the account are identical' do
          expect(last_response.status).to be 422
        end
        it 'Returns the correct body when the creator and the account are identical' do
          expect(JSON.parse(last_response.body)).to eq({'errors' => ['invitation.account.is_creator']})
        end
        it 'Does not create an invitation when the account and the creator are identical' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 0
        end
      end
      describe 'The user is already existing in the campaign as a pending invitation' do
        let!(:invitation) { create(:invitation, accepted: false, account: account, creator: creator, campaign: campaign) }

        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns an Unprocessable Entity (422) response code when the account already has a pending invitation' do
          expect(last_response.status).to be 422
        end
        it 'Returns the correct body when the account already has a pending invitation' do
          expect(JSON.parse(last_response.body)).to eq({'errors' => ['invitation.account.already_pending']})
        end
        it 'Does not create an invitation if the account already has a pending invitation' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 1
        end
      end
      describe 'The user is already existing in the campaign as an accepted invitation' do
        let!(:invitation) { create(:invitation, accepted: true, account: account, creator: creator, campaign: campaign) }

        before do
          post '/', {token: 'test_token', app_key: 'test_key', username: account.username, session_id: session.token, campaign_id: campaign.id.to_s}
        end
        it 'Returns an Unprocessable Entity (422) response code when the account already has an accepted invitation' do
          expect(last_response.status).to be 422
        end
        it 'Returns the correct body when the account already has an accepted invitation' do
          expect(JSON.parse(last_response.body)).to eq({'errors' => ['invitation.account.already_accepted']})
        end
        it 'Does not create an invitation if the account already has an accepted invitation' do
          expect(Arkaan::Campaigns::Invitation.all.count).to be 1
        end
      end
    end
  end
end