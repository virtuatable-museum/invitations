module Services
  module Invitations
    class Creation
      include Singleton

      # Creates an invitation for the given user, in the given campaign.
      # @param session [Arkaan::Authentication::Session] the session of the user creating the current invitation.
      # @param campaign [Arkaan::Campaign] the campaign in which create the invitation.
      # @param account [Arkaan::Account] the account of the user invited in the application.
      def create(session, campaign, account)
        if account.id.to_s == campaign.creator.id.to_s
          raise Arkaan::Utils::Errors::BadRequest.new(action: 'creation', field: 'username', error: 'already_accepted')
        end
        existing = Arkaan::Campaigns::Invitation.where(campaign: campaign, account: account).first
        status = session.account.id.to_s == campaign.creator.id.to_s ? :pending : :request

        if existing.nil?
          parameters = {account: account, campaign: campaign, enum_status: status}
          existing = Arkaan::Campaigns::Invitation.create(parameters)
        else
          # If the invitation has already been issued from one side and hasn't been accepted by the other.
          if existing.status_accepted? || existing.status_pending? || existing.status_request?
            raise Arkaan::Utils::Errors::BadRequest.new(action: 'creation', field: 'username', error: "already_#{existing.status.to_s}")
          # If the user has been blocked by the creator of the campaign after a previous request.
          elsif existing.status_blocked? && session.account.id.to_s != campaign.creator.id.to_s
            raise Arkaan::Utils::Errors::Forbidden.new(action: 'creation', field: 'username', error: 'blocked')
          # If the creator of the campaign has been ignored by the user after a previous invitation.
          elsif existing.status_ignored? && session.account.id.to_s == campaign.creator.id.to_s
            raise Arkaan::Utils::Errors::Forbidden.new(action: 'creation', field: 'username', error: 'ignored')
          end
          existing.status = status
          existing.save
        end
        post_create(session, existing) if existing.persisted?
        return existing
      end

      # Sends a request on the websockets service to notify the user concerned by the invitation.
      # @param session [Arkaan::Authentication::Session] the session of the user to notify
      # @param invitation [Arkaan::Campaigns::Invitation] the invitation created, sent as additional data to the service.
      def post_create(session, invitation)
        account = invitation.status_request? ? invitation.campaign.creator : invitation.account
        Arkaan::Factories::Gateways.random('create').post(
          session: session,
          url: '/repartitor/messages',
          params: {
            message: 'invitation_creation',
            data: Decorators::Invitation.new(invitation).to_h,
            account_id: account.id.to_s
          })
      end
    end
  end
end