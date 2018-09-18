module Decorators
  class Invitation < Draper::Decorator
    delegate_all

    def to_h
      campaign = object.campaign
      return {
        id: object.id.to_s,
        status: object.status.to_s,
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
  end
end