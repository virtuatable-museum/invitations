module Controllers
  class Invitations < Arkaan::Utils::Controller

    load_errors_from __FILE__

    declare_route 'post', '/' do
      check_presence('session_id', 'campaign_id', 'username', route: 'creation')

      account = Arkaan::Account.where(username: params['username']).first
      custom_error(404, 'creation.username.unknown') if account.nil?

      campaign = Arkaan::Campaign.where(id: params['campaign_id']).first
      custom_error(404, 'creation.campaign_id.unknown') if campaign.nil?

      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      custom_error(404, 'creation.session_id.unknown') if session.nil?
      custom_error(403, 'creation.session_id.forbidden') if session.account.id != campaign.creator.id

      custom_error(400, 'creation.username.already_accepted') if session.account.id.to_s == account.id.to_s

      existing = Arkaan::Campaigns::Invitation.where(account: account, creator: session.account, campaign: campaign).first
      custom_error(400, "creation.username.already_#{existing.accepted ? 'accepted' : 'pending'}") if !existing.nil?

      invitation = Arkaan::Campaigns::Invitation.create(account: account, creator: session.account, campaign: campaign, accepted: false)
      halt 201, {message: 'created', item: Decorators::Invitation.new(invitation).to_h}.to_json
    end

    declare_route 'get', '/own' do
      check_presence('session_id', route: 'own_invitations')
      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      custom_error(404, 'creation.session_id.unknown') if session.nil?

      pending = session.account.invitations.where(accepted: false)
      dec_pending = Decorators::Invitation.decorate_collection(pending).map(&:with_campaign)
      accepted = session.account.invitations.where(accepted: true)
      dec_accepted = Decorators::Invitation.decorate_collection(accepted).map(&:with_campaign)

      halt 200, {
        pending: {count: pending.count, items: dec_pending},
        accepted: {count: accepted.count, items: dec_accepted}
      }.to_json
    end

    declare_route 'put', '/:id' do
      invitation = check_before_invitation_update('update')
      if params['accepted'] && params['accepted'] == 'true'
        invitation.accepted = true
        invitation.save
      end
      halt 200, {message: 'updated'}.to_json
    end

    declare_route 'delete', '/:id' do
      invitation = check_before_invitation_update('deletion')
      invitation.delete
      halt 200, {message: 'deleted'}.to_json
    end

    def check_before_invitation_update(mode)
      check_presence('session_id', route: mode)
      session = Arkaan::Authentication::Session.where(token: params['session_id']).first
      custom_error(404, "#{mode}.session_id.unknown") if session.nil?

      invitation = Arkaan::Campaigns::Invitation.where(id: params['id']).first
      custom_error(404, "#{mode}.invitation_id.unknown") if invitation.nil?

      if mode == 'deletion'
        if ![invitation.account.id.to_s, invitation.creator.id.to_s].include?(session.account.id.to_s)
          custom_error(403, "#{mode}.session_id.forbidden")
        end
      else
        if invitation.account.id.to_s != session.account.id.to_s
          custom_error(403, "#{mode}.session_id.forbidden")
        end
      end
      return invitation
    end
  end
end