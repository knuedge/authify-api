module Authify
  module API
    module Models
      # High-level logical organization of groups and users
      class Organization < ActiveRecord::Base
        include JSONAPIUtils

        validates_uniqueness_of :name

        has_many :organization_memberships,
                 class_name: 'Authify::API::Models::OrganizationMembership',
                 dependent: :destroy

        has_many :users,
                 through: :organization_memberships,
                 class_name: 'Authify::API::Models::User'

        has_many :groups,
                 class_name: 'Authify::API::Models::Group',
                 dependent: :destroy

        has_many :admins, -> { where admin: true },
                 through: :organization_memberships,
                 class_name: 'Authify::API::Models::User',
                 source: 'user'
      end
    end
  end
end
