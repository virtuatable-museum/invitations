module Services
  module Invitations
    class Deletion
      include Singleton

      # Deletes an invitation if the user linked to the session is authorized to.
      # @param session [Arkaan::Authentication::Session] the session of the user trying to delete this invitation.
      # @param invitation [Arkaan::Campaigns::Invitation] the invitation to delete.
      def delete(session, invitation)
        if ![:pending, :request].include?(invitation.status.to_sym)
          raise Arkaan::Utils::Errors::BadRequest.new(action: 'deletion', field: 'invitation_id', error: "impossible_deletion")
        elsif invitation.status_pending? && session.account.id.to_s != invitation.campaign.creator.id.to_s
          raise Arkaan::Utils::Errors::Forbidden.new(action: 'deletion', field: 'session_id', error: "forbidden")
        elsif invitation.status_request? && session.account.id.to_s != invitation.account.id.to_s
          raise Arkaan::Utils::Errors::Forbidden.new(action: 'deletion', field: 'session_id', error: "forbidden")
        end
        return invitation.delete
      end
    end
  end
end