module Decorators
  class Invitation < Draper::Decorator
    delegate_all

    def to_h
      return {
        id: object.id.to_s,
        creator: object.creator.username,
        username: object.account.username
      }
    end

    # Returns the hash representation of this invitation with the informations about its campaign
    # @return [Hash] the hash representation of the invitation and the campaign
    def with_campaign
      return {
        id: object.id.to_s,
        campaign: {
          id: object.campaign.id.to_s,
          title: object.campaign.title,
          description: object.campaign.description,
          creator: {
            id: object.campaign.creator.id.to_s,
            username: object.campaign.creator.username
          },
          is_private: object.campaign.is_private,
          tags: object.campaign.tags
        }
      }
    end
  end
end