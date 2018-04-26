module Controllers
  class Invitations < Arkaan::Utils::Controller

    load_errors_from __FILE__

    configure do
      set :show_exceptions, false
    end

    declare_route 'post', '/' do
      session = check_session('creation')
      account = check_account('creation')
      campaign = check_campaign('creation')

      invitation = Services::Invitations.instance.create(session, campaign, account)

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

    # Checks the presence of the username, and the existence of the associated account.
    # @param action [String] the action used as a key in the configuration file to find the associated error.
    # @return [Arkaan::Account] the account if it's been found and has not raised any error.
    def check_account(action)
      check_presence('username', route: action)
      account = Arkaan::Account.where(username: params['username']).first
      custom_error(404, "#{action}.username.unknown") if account.nil?
      return account
    end

    # Checks the presence of the campaign ID, and the existence of the associated campaign.
    # @param action [String] the action used as a key in the configuration file to find the associated error.
    # @return [Arkaan::Campaign] the campaign if it's been found and has not raised any error.
    def check_campaign(action)
      check_presence('campaign_id', route: action)
      campaign = Arkaan::Campaign.where(id: params['campaign_id']).first
      custom_error(404, "#{action}.campaign_id.unknown") if campaign.nil?
      return campaign
    end

  end
end