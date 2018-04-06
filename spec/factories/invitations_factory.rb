FactoryGirl.define do
  factory :empty_invitation, class: Arkaan::Campaigns::Invitation do
    id 'invitation_id'
    factory :invitation do
      factory :pending_invitation do
        accepted false
      end
      factory :accepted_invitation do
        accepted true
      end
    end
  end
end