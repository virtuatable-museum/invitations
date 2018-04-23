module Services
  class Invitations
    include Singleton

    # Creates an invitation for the given user, in the given campaign.
    # @param session [Arkaan::Authentication::Session] the session of the user creating the current invitation.
    # @param campaign [Arkaan::Campaign] the campaign in which create the invitation.
    # @param account [Arkaan::Account] the account of the user invited in the application.
    def create(session, campaign, account)
      parameters = {
        account: account,
        campaign: campaign,
        enum_status: session.account.id.to_s == campaign.creator.id.to_s ? :pending : :request
      }
      return Arkaan::Campaigns::Invitation.create(parameters)
    end

  end
end