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
        invitation.update_attribute(:status, status)
        return invitation
      end
    end
  end
end