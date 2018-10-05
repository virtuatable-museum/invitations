module Services
  module Invitations
    class Update
      include Singleton

      # @!attribute [rw] rules
      #   @return [Hash] the rules of update as a hash.
      attr_accessor :rules

      # Loads the rules about the update, simplifying the process.
      def load_rules!
        @rules = YAML::load_file(File.join(__dir__, '..', '..', 'config', 'rules.yml'))
      end

      # Updates the invitation with the given status.
      # @param session [Arkaan::Authentication::Session] the session of the user trying to update the invitation.
      # @param invitation [Arkaan::Campaigns::Invitation] the invitation to update
      # @param status [Symbol, String] the new status to set on the invitation.
      def update(session, invitation, status)
        # If nothing needs to be modified, just return the invitation and indicates the user it has been updated.
        if invitation.status == status.to_sym
          return invitation
        # No invitation can be updated to request or pending, the user needs to create a new one.
        elsif [:pending, :request].include? status.to_sym
          raise Arkaan::Utils::Errors::BadRequest.new(action: 'update', field: 'status', error: 'use_creation')
        # If there are no rule of update between the current status and the wanted one, indicate it.
        elsif rules[invitation.status.to_s].nil? || rules[invitation.status.to_s][status.to_s].nil?
          raise Arkaan::Utils::Errors::BadRequest.new(action: 'update', field: 'status', error: 'impossible')
        else
          rule = rules[invitation.status.to_s][status.to_s]
          # If the rule indicates that only the creator can update from the current state to the wanted one, and it's not him/her.
          if rule == 'creator' && session.account.id.to_s != invitation.campaign.creator.id.to_s
            raise Arkaan::Utils::Errors::Forbidden.new(action: 'update', field: 'session_id', error: 'forbidden')
          # If the rule indicates that only the account can update from the current state to the wanted one, and it's not him/her.
          elsif rule == 'user' && session.account.id.to_s != invitation.account.id.to_s
            raise Arkaan::Utils::Errors::Forbidden.new(action: 'update', field: 'session_id', error: 'forbidden')
          end
        end
        # The account is set regarding the PREVIOUS state of the invitation, before updating it.
        account = invitation.status_request? ? invitation.account : invitation.campaign.creator
        invitation.status = status
        invitation.save
        post_update(session, account, invitation) if invitation.valid?
        return invitation
      end

      # Sends a request on the websockets service to notify the user concerned by the invitation.
      # @param session [Arkaan::Authentication::Session] the session of the user to notify
      # @param account [Arkaan::Account] the account of the person supposed to receive the message.
      # @param invitation [Arkaan::Campaigns::Invitation] the invitation created, sent as additional data to the service.
      def post_update(session, account, invitation)
        if !invitation.status_blocked? && !invitation.status_ignored?
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
end