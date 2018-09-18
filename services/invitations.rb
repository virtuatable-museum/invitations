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
      receiver = invitation.status_request? ? invitation.campaign.creator : invitation.account
      Arkaan::Factories::Gateways.random('create').post(
        session: session,
        url: '/websockets/messages',
        params: {
          message: 'invitation_creation',
          data: Decorators::Invitation.new(invitation).to_h,
          receiver: receiver.username
        })
    end

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
      # The receiver is set regarding the PREVIOUS state of the invitation, before updating it.
      receiver = invitation.status_request? ? invitation.account : invitation.campaign.creator
      invitation.status = status
      invitation.save
      post_update(session, receiver, invitation) if invitation.valid?
      return invitation
    end

    # Sends a request on the websockets service to notify the user concerned by the invitation.
    # @param session [Arkaan::Authentication::Session] the session of the user to notify
    # @param receiver [Arkaan::Account] the account of the person supposed to receive the message.
    # @param invitation [Arkaan::Campaigns::Invitation] the invitation created, sent as additional data to the service.
    def post_update(session, receiver, invitation)
      Arkaan::Factories::Gateways.random('create').post(
        session: session,
        url: '/websockets/messages',
        params: {
          message: 'invitation_update',
          data: Decorators::Invitation.new(invitation).to_h,
          receiver: receiver.username
        })
    end

    # Gets the list of invitations concerning the given session. Selected invitations are :
    # - Any invitations where the account is the session's account
    # - Any request made to a campaign that was created by the session's account
    # @param session [Arkaan::Authentication::Session] the session the user is connected on.
    # @return [Hash<Symbol, Array<Arkaan::Campaigns::Invitation>>] the invitations grouped by status.
    def list(session)
      criteria = [
        {account: session.account, :enum_status.in => [:accepted, :pending, :request]},
        {enum_status: :request, :campaign_id.in => session.account.campaign_ids}
      ]
      order_by = {enum_status: :asc}
      invitations =  Arkaan::Campaigns::Invitation.any_of(*criteria).order_by(order_by)
      return Decorators::Invitation.decorate_collection(invitations).map(&:to_h)
    end
  end
end