module Controllers
  class Invitations < Arkaan::Utils::Controller

    load_errors_from __FILE__

    declare_route 'post', '/' do
      check_presence('campaign_id', 'username', route: 'creation')

      session = check_session('creation')

      account = Arkaan::Account.where(username: params['username']).first
      custom_error(404, 'creation.username.unknown') if account.nil?

      campaign = Arkaan::Campaign.where(id: params['campaign_id']).first
      custom_error(404, 'creation.campaign_id.unknown') if campaign.nil?

      custom_error(403, 'creation.session_id.forbidden') if session.account.id != campaign.creator.id

      custom_error(400, 'creation.username.already_accepted') if session.account.id.to_s == account.id.to_s

      existing = Arkaan::Campaigns::Invitation.where(account: account, creator: session.account, campaign: campaign).first
      custom_error(400, "creation.username.already_#{existing.status.to_s}") if !existing.nil?

      invitation = Arkaan::Campaigns::Invitation.create(account: account, creator: session.account, campaign: campaign, status: :pending)
      halt 201, {message: 'created', item: Decorators::Invitation.new(invitation).to_h}.to_json
    end

    declare_route 'get', '/own' do
      session = check_session('own_invitations')
      results = {}

      [:accepted, :pending].each do |status|
        items = session.account.invitations.where(enum_status: status)
        results[status] = {
          count: items.count,
          items: Decorators::Invitation.decorate_collection(items).map(&:with_campaign)
        }
      end

      halt 200, results.to_json
    end

    declare_route 'put', '/:id' do
      session = check_session('update')

      invitation = Arkaan::Campaigns::Invitation.where(id: params['id']).first
      custom_error(404, "update.invitation_id.unknown") if invitation.nil?

      custom_error(403, "update.session_id.forbidden") if invitation.account.id.to_s != session.account.id.to_s
  
      invitation.update_attributes(status: params['status'] || invitation.enum_status)
      halt 200, {message: 'updated'}.to_json
    end

  end
end