module Decorators
  class Invitation < Draper::Decorator
    delegate_all

    def to_h
      return {
        id: object.id.to_s,
        username: object.account.username
      }
    end

    # Returns the hash representation of this invitation with the informations about its campaign
    # @return [Hash] the hash representation of the invitation and the campaign
    def with_campaign
      campaign = object.campaign
      return {
        id: object.id.to_s,
        created_at: object.created_at.utc.iso8601,
        campaign: {
          id: campaign.id.to_s,
          title: campaign.title,
          creator: campaign.creator.username,
          description: campaign.description,
          is_private: campaign.is_private,
          tags: campaign.tags
        }
      }
    end

    def as_request
      return {
        id: object.id.to_s,
        created_at: object.created_at.utc.iso8601,
        username: object.account.username,
        campaign: {
          id: object.campaign.id.to_s,
          title: object.campaign.title,
        }
      }
    end

    def to_complete_h
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
          is_private: campaign.is_private,
          tags: campaign.tags
        }
      }
    end
  end
end