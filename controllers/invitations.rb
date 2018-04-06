module Controllers
  class Invitations < Arkaan::Utils::Controller
    declare_route 'post', '/' do
      check_presence('session_id', 'campaign_id', 'username')
      account = Arkaan::Account.where(username: params['username']).first
      if account.nil?
        halt 404, {errors: ['invitation.account.not_found']}.to_json
      end
      campaign = Arkaan::Campaign.where(id: params['campaign_id']).first
      if campaign.nil?
        halt 404, {errors: ['invitation.campaign.not_found']}.to_json
      end
      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      if session.nil?
        halt 404, {errors: ['invitation.session.not_found']}.to_json
      end
      if session.account.id.to_s != campaign.creator.id.to_s
        halt 403, {errors: ['invitation.session.not_authorized']}.to_json
      end
      if session.account.id.to_s == account.id.to_s
        halt 422, {errors: ['invitation.account.not_creator']}.to_json
      end
      already_existing = Arkaan::Campaigns::Invitation.where(account: account, creator: session.account, campaign: campaign).first
      if !already_existing.nil?
        halt 422, {errors: ["invitation.account.already_#{already_existing.accepted ? 'accepted' : 'pending'}"]}.to_json
      end
      Arkaan::Campaigns::Invitation.create(account: account, creator: session.account, campaign: campaign, accepted: false)
      halt 201, {message: 'created'}.to_json
    end

    declare_route 'put', '/:id' do
      invitation = check_before_invitation_update
      if params['accepted'] && params['accepted'] == 'true'
        invitation.accepted = true
        invitation.save
      end
      halt 200, {message: 'updated'}.to_json
    end

    declare_route 'delete', '/:id' do
      invitation = check_before_invitation_update(creator_allowed: true)
      invitation.delete
      halt 200, {message: 'deleted'}.to_json
    end

    def check_before_invitation_update(creator_allowed: false)
      check_presence 'session_id'
      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      if session.nil?
        halt 404, {errors: ['invitation.session.not_found']}.to_json
      end
      invitation = Arkaan::Campaigns::Invitation.where(id: params['id']).first
      if invitation.nil?
        halt 404, {errors: ['invitation.id.not_found']}.to_json
      end
      if creator_allowed
        if ![invitation.account.id.to_s, invitation.creator.id.to_s].include?(session.account.id.to_s)
          halt 403, {errors: ['invitation.account.not_authorized']}.to_json
        end
      else
        if invitation.account.id.to_s != session.account.id.to_s
          halt 403, {errors: ['invitation.account.not_authorized']}.to_json
        end
      end
      return invitation
    end
  end
end