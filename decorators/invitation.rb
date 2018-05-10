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
      return {
        id: object.id.to_s,
        created_at: object.created_at.utc.iso8601,
        campaign: {
          id: object.campaign.id.to_s,
          title: object.campaign.title,
          creator: object.campaign.creator.username
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
  end
end