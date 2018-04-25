module Services
  class Invitations
    include Singleton

    # Creates an invitation for the given user, in the given campaign.
    # @param session [Arkaan::Authentication::Session] the session of the user creating the current invitation.
    # @param campaign [Arkaan::Campaign] the campaign in which create the invitation.
    # @param account [Arkaan::Account] the account of the user invited in the application.
    def create(session, campaign, account)
      existing = Arkaan::Campaigns::Invitation.where(campaign: campaign, account: account).first
      status = session.account.id.to_s == campaign.creator.id.to_s ? :pending : :request
      if !existing.nil?
        return update(existing, status, action: 'creation')
      else
        parameters = {account: account, campaign: campaign, enum_status: status}
        return Arkaan::Campaigns::Invitation.create(parameters)
      end
    end

    def update(existing, status, action: 'update')
      if existing.status_pending?
        raise Arkaan::Utils::Errors::BadRequest.new(action: action, field: 'username', error: 'already_pending')
      end
    end

  end
end