module Services
  # Big service of invitations update/creation, managing the permissions to do so.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Invitations
    include Singleton

    # @!attribute [rw] rules
    #   @return [Hash] the rules of update as a hash.
    attr_accessor :rules

    # Loads the rules about the update, simplifying the process.
    def load_rules!
      @rules = YAML::load_file(File.join(__dir__, '..', 'config', 'rules.yml'))
    end

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
        return Arkaan::Campaigns::Invitation.create(parameters)
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
        return existing
      end
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
      invitation.status = status
      invitation.save
      return invitation
    end

    # Gets the list of invitations concerning the given session. Selected invitations are :
    # - Any invitations where the account is the session's account
    # - Any request made to a campaign that was created by the session's account
    # @param session [Arkaan::Authentication::Session] the session the user is connected on.
    # @return [Hash<Symbol, Array<Arkaan::Campaigns::Invitation>>] the invitations grouped by status.
    def list(session)
      return {
        accepted: get_invitations(:accepted, session),
        pending: get_invitations(:pending, session),
        request: get_requests(session)
      }
    end

    # Gets the invitations for the given session, with the given status, and decorates it with campaigns.
    # @param status [Symbol, String] the status you want to select the invitations on.
    # @param session [Arkaan::Authentication::Session] the session of the account you want the invitations from.
    # @return [Hash] a hash with the count and items for this status and account.
    def get_invitations(status, session)
      invitations = Arkaan::Campaigns::Invitation.where(enum_status: status, account: session.account)
      return {
        count: invitations.count,
        items: Decorators::Invitation.decorate_collection(invitations).map(&:with_campaign)
      }
    end

    # Get all the requests in the campaign created by the account linked to the given session.
    # @param session [Arkaan::Authentication::Session] the session of the account you want the requests from.
    # @return [Hash] a hash with the count and items for the desired requests.
    def get_requests(session)
      campaign_ids = Arkaan::Campaign.where(creator: session.account).pluck(:_id)
      requests = Arkaan::Campaigns::Invitation.where(enum_status: :request, :campaign_id.in => campaign_ids)
      return {
        count: requests.count,
        items: Decorators::Invitation.decorate_collection(requests).map(&:as_request)
      }
    end
  end
end