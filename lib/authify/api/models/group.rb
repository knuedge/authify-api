module Authify
  module API
    module Models
      # A way of grouping multiple users
      class Group < ActiveRecord::Base
        include JSONAPIUtils

        validates_uniqueness_of :name, scope: :organization_id

        belongs_to :organization,
                   required: true,
                   class_name: 'Authify::API::Models::Organization'

        has_and_belongs_to_many :users,
                                class_name: 'Authify::API::Models::User'
      end
    end
  end
end
