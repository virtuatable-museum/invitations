# frozen_string_literal: true

require 'sinatra/custom_logger'

module Controllers
  # Main controller for creating, updating, deleting and listing invitations.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Invitations < Arkaan::Utils::Controllers::Checked
    helpers Sinatra::CustomLogger

    load_errors_from __FILE__

    Services::Invitations::Update.instance.load_rules!

    configure do
      set :show_exceptions, false
      set :logger, Logger.new(STDOUT)
    end

    def initialize
      super
      create_app
    end

    declare_status_route

    declare_route 'post', '/' do
      session = check_session('creation')
      account = check_account('creation')
      campaign = check_campaign('creation')

      invit = create_service.create(session, campaign, account)

      halt 201, { message: 'created', item: decorate(invit) }.to_json
    end

    declare_route 'get', '/' do
      session = check_session('own_invitations')
      results = Services::Invitations::Listing.instance.list(session)

      halt 200, results.to_json
    end

    declare_route 'put', '/:id' do
      check_presence('status', route: 'update')

      invit = update_service.update(
        check_session('update'),
        check_invitation('update'),
        params['status']
      )

      halt 200, { message: 'updated', item: decorate(invit) }.to_json
    end

    declare_route 'delete', '/:id' do
      session = check_session('deletion')
      invit = check_invitation('update')

      delete_service.delete(session, invit)

      halt 200, { message: 'deleted' }.to_json
    end

    private

    def create_service
      Services::Invitations::Creation.instance
    end

    def update_service
      Services::Invitations::Update.instance
    end

    def delete_service
      Services::Invitations::Deletion.instance
    end

    def decorate(invitation)
      Decorators::Invitation.new(invitation).to_h
    end

    # Checks the presence of the username, and the existence of the account.
    # @param action [String] the action used to find the associated error.
    # @return [Arkaan::Account] the account if it's been found.
    def check_account(action)
      check_presence('username', route: action)
      account = Arkaan::Account.where(username: params['username']).first
      custom_error(404, "#{action}.username.unknown") if account.nil?
      account
    end

    def check_invitation(action)
      invitation = Arkaan::Campaigns::Invitation.where(id: params['id']).first
      custom_error(404, "#{action}.invitation_id.unknown") if invitation.nil?
      invitation
    end

    # Checks the presence of the campaign ID, and the existence of the campaign.
    # @param action [String] the action used to find the associated error.
    # @return [Arkaan::Campaign] the campaign if it's been found.
    def check_campaign(action)
      check_presence('campaign_id', route: action)
      campaign = Arkaan::Campaign.where(id: params['campaign_id']).first
      custom_error(404, "#{action}.campaign_id.unknown") if campaign.nil?
      campaign
    end

    def create_app
      account = Arkaan::Account.where(username: ENV['USERNAME']).first
      application = Arkaan::OAuth::Application.find_or_create_by(
        name: 'invitations',
        premium: true,
        creator: account
      )
      application.save
      @oauth_app = application
    end
  end
end
