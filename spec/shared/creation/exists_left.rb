RSpec.shared_examples 'invitation exists with a left status' do
  describe 'when the invitation already exists with a left status' do
    let!(:existing_invitation) { create(:invitation, status: :left, campaign: campaign, account: account) }

    describe 'created by a user' do
      before do
        post '/', {session_id: account_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Created (201) status' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        invitation = Arkaan::Campaigns::Invitation.first
        expect(last_response.body).to include_json({message: 'created'})
      end
      it 'Does not create a new invitation' do
        expect(Arkaan::Campaigns::Invitation.all.count).to be 1
      end
      it 'has correctly updated the invitation status' do
        expect(Arkaan::Campaigns::Invitation.first.status).to eq :request
      end
    end
    describe 'created by campaign creator' do
      before do
        post '/', {session_id: creator_session.token, app_key: 'test_key', token: 'test_token', username: account.username, campaign_id: campaign.id.to_s}
      end
      it 'Returns a Created (201) status' do
        expect(last_response.status).to be 201
      end
      it 'Returns the correct body' do
        invitation = Arkaan::Campaigns::Invitation.first
        expect(last_response.body).to include_json({message: 'created'})
      end
      it 'Does not create a new invitation' do
        expect(Arkaan::Campaigns::Invitation.all.count).to be 1
      end
      it 'has correctly updated the invitation status' do
        expect(Arkaan::Campaigns::Invitation.first.status).to eq :pending
      end
    end
  end
end