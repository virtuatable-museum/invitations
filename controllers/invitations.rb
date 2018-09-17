module Controllers
  class Invitations < Arkaan::Utils::Controller

    load_errors_from __FILE__

    Services::Invitations.instance.load_rules!

    configure do
      set :show_exceptions, false
    end

    def initialize
      super
      create_app
    end

    declare_route 'post', '/' do
      session = check_session('creation')
      account = check_account('creation')
      campaign = check_campaign('creation')

      invitation = Services::Invitations.instance.create(session, campaign, account)

      halt 201, {message: 'created', item: Decorators::Invitation.new(invitation).to_h}.to_json
    end

    declare_route 'get', '/' do
      session = check_session('own_invitations')
      results = Services::Invitations.instance.list(session)

      halt 200, results.to_json
    end

    declare_route 'put', '/:id' do
      check_presence('status', route: 'update')

      session = check_session('update')
      invitation = check_invitation('update')
  
      Services::Invitations.instance.update(session, invitation, params['status'])

      halt 200, {message: 'updated'}.to_json
    end

    declare_route 'delete', '/:id' do
      session = check_session('deletion')
      invitation = check_invitation('update')

      Services::Invitations.instance.delete(session, invitation)

      halt 200, {message: 'deleted'}.to_json
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

    def check_invitation(action)
      invitation = Arkaan::Campaigns::Invitation.where(id: params['id']).first
      custom_error(404, "#{action}.invitation_id.unknown") if invitation.nil?
      return invitation
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

    def create_app
      account = Arkaan::Account.where(username: ENV['USERNAME']).first
      application = Arkaan::OAuth::Application.find_or_create_by(name: 'invitations', premium: true, creator: account)
      application.save
      @oauth_app = application
    end

  end
end