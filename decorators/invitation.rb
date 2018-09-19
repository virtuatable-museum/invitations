module Decorators
  class Invitation < Draper::Decorator
    delegate_all

    def to_h(session = nil)
      status = session.nil? ? object.status.to_s : status(session)
      campaign = object.campaign
      return {
        id: object.id.to_s,
        status: status,
        created_at: object.created_at.utc.iso8601,
        username: object.account.username,
        campaign: {
          id: campaign.id.to_s,
          title: campaign.title,
          creator: campaign.creator.username,
          description: campaign.description,
          max_players: campaign.max_players,
          current_players: campaign.invitations.where(enum_status: :accepted).count,
          is_private: campaign.is_private,
          tags: campaign.tags
        }
      }
    end

    def status(session)
      if object.status_blocked? && object.account.id.to_s == session.account.id.to_s
        return 'request'
      else
        return object.status.to_s
      end
    end
  end
end