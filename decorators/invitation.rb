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
  end
end