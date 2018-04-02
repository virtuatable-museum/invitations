module Controllers
  class Invitations < Arkaan::Utils::Controller
    post '/' do
      check_presence('session_id', 'campaign_id', 'account_id')
      account = Arkaan::Account.where(id: params['account_id']).first
      if account.nil?
        halt 404, {message: 'account_not_found'}.to_json
      end
      campaign = Arkaan::Campaign.where(id: params['campaign_id']).first
      if campaign.nil?
        halt 404, {message: 'campaign_not_found'}.to_json
      end
      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      if session.nil?
        halt 404, {message: 'session_not_found'}.to_json
      end
      if session.account.id.to_s != campaign.creator.id.to_s
        halt 403, {message: 'not_authorized'}.to_json
      end
      if session.account.id.to_s == account.id.to_s
        halt 422, {errors: ['invitation.account.is_creator']}.to_json
      end
      already_existing = Arkaan::Campaigns::Invitation.where(account: account, creator: session.account, campaign: campaign).first
      if !already_existing.nil?
        halt 422, {errors: ["invitation.account.already_#{already_existing.accepted ? 'accepted' : 'pending'}"]}.to_json
      end
      Arkaan::Campaigns::Invitation.create(account: account, creator: session.account, campaign: campaign, accepted: false)
      halt 201, {message: 'created'}.to_json
    end
  end
end