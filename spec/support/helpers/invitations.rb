module Helpers
  module Invitations
    def get_invitations
      Arkaan::Campaigns::Invitation.where(:enum_status.ne => :creator)
    end
  end
end

RSpec.configure do |config|
  config.include Helpers::Invitations
end