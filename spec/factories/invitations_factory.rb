FactoryGirl.define do
  factory :empty_invitation, class: Arkaan::Campaigns::Invitation do
    id 'invitation_id'
    factory :invitation do
      factory :pending_invitation do
        status :pending
      end
      factory :accepted_invitation do
        status :accepted
      end
    end
  end
end