module Services
  module Invitations
    class Listing
      include Singleton

      # Gets the list of invitations concerning the given session. Selected invitations are :
      # - Any invitations where the account is the session's account
      # - Any request made to a campaign that was created by the session's account
      # @param session [Arkaan::Authentication::Session] the session the user is connected on.
      # @return [Hash<Symbol, Array<Arkaan::Campaigns::Invitation>>] the invitations grouped by status.
      def list(session)
        criteria = [
          {account: session.account, :enum_status.in => [:accepted, :pending, :request, :ignored, :blocked]},
          {:enum_status.in => [:blocked, :request], :campaign_id.in => session.account.campaign_ids}
        ]
        order_by = {enum_status: :asc}
        invitations =  Arkaan::Campaigns::Invitation.any_of(*criteria).order_by(order_by)
        return Decorators::Invitation.decorate_collection(invitations).map { |inv| inv.to_h(session) }
      end
    end
  end
end