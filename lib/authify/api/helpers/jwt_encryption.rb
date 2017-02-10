module Authify
  module API
    module Helpers
      # Helper methods for working with JWT encryption
      module JWTEncryption
        include Core::Helpers::JWTSSL

        def jwt_token(user = nil)
          user ||= current_user
          JWT.encode jwt_payload(user), private_key, CONFIG[:jwt][:algorithm]
        end

        def jwt_payload(user)
          {
            exp: Time.now.to_i + 60 * CONFIG[:jwt][:expiration].to_i,
            iat: Time.now.to_i,
            iss: CONFIG[:jwt][:issuer],
            scopes: Core::Constants::JWTSCOPES,
            user: {
              username: user.email,
              uid: user.id,
              organizations: simple_orgs_by_user(user)
            }
          }
        end

        def simple_orgs_by_user(user)
          user.organizations.map do |o|
            {
              name: o.name,
              oid: o.id,
              admin: o.admins.include?(user),
              memberships: o.groups.select { |g| g.users.include?(user) }.map do |g|
                { name: g.name, gid: g.id }
              end
            }
          end
        end

        def with_jwt(req, scope)
          scopes, user = req.env.values_at :scopes, :user
          set_current_user Models::User.from_username(user['username'])

          if scopes.include?(scope) && current_user
            yield req
          else
            halt 403
          end
        end
      end
    end
  end
end
