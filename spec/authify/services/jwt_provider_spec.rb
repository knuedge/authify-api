require 'spec_helper'

# Tests for the /jwt endpoints
describe Authify::API::Services::JWTProvider do
  include Rack::Test::Methods

  def app
    Authify::API::Services::JWTProvider
  end

  context 'mounted at /jwt' do
    # /meta and /key
    context 'informational endpoints' do
      let(:expected_meta) do
        {
          'algorithm'  => ENV['AUTHIFY_JWT_ALGORITHM'],
          'issuer'     => 'My Awesome Company Inc.',
          'expiration' => 15
        }
      end

      let(:jwt_public_key) do
        File.read(ENV['AUTHIFY_PUBKEY_PATH'])
      end

      context 'OPTIONS /meta' do
        it 'returns 200 with expected headers' do
          options '/meta'

          # Should respond with a 200
          expect(last_response.status).to eq(200)
          expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
        end
      end

      context 'GET /meta' do
        it 'provides JWT meta information' do
          header 'Accept', 'application/json'
          get '/meta'

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(3)
          expect(details).to eq(expected_meta)
        end
      end

      context 'GET /key' do
        it 'provides the JWT public key' do
          header 'Accept', 'application/json'
          get '/key'

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(1)
          expect(details).to eq('data' => jwt_public_key)
        end
      end
    end

    # /token
    context 'token provider endpoint' do
      let(:incorrect_credentials) do
        {
          'email' => RSpec.configuration.test_user.email,
          'password' => 'foobar123'
        }.to_json
      end

      let(:api_auth_data) do
        {
          'access-key' => RSpec.configuration.test_user_apikey.access_key,
          'secret-key' => RSpec.configuration.test_user_apikey.secret_key
        }.to_json
      end

      let(:api_auth_with_custom_payload_data) do
        {
          'access-key' => RSpec.configuration.test_user_apikey.access_key,
          'secret-key' => RSpec.configuration.test_user_apikey.secret_key,
          'inject' => { 'foo' => 'bar' }
        }.to_json
      end

      let(:user_auth_data) do
        {
          'email' => RSpec.configuration.test_user.email,
          'password' => 'testuser123'
        }.to_json
      end

      let(:trusted_delegate_auth_data) do
        {
          'provider' => RSpec.configuration.test_user_identity.provider,
          'uid' => RSpec.configuration.test_user_identity.uid
        }.to_json
      end

      let(:jwt_options) do
        {
          algorithm: ENV['AUTHIFY_JWT_ALGORITHM'],
          verify_iss: true,
          verify_iat: true,
          iss: 'My Awesome Company Inc.'
        }
      end

      context 'POST /token' do
        context 'with incorrect credentials' do
          it 'returns 401' do
            header 'Accept', 'application/json'
            header 'Content-Type', 'application/json'
            post '/token', incorrect_credentials

            # Should respond with a 401
            expect(last_response.status).to eq(401)
          end
        end

        context 'using an email and password' do
          it 'provides a usable JWT' do
            header 'Accept', 'application/json'
            header 'Content-Type', 'application/json'
            post '/token', user_auth_data

            # Should respond with a 200
            expect(last_response.status).to eq(200)

            details = JSON.parse(last_response.body)

            expect(details.size).to eq(1)
            expect(details).to have_key('jwt')
          end
        end

        context 'using an API access key and secret' do
          it 'provides a usable JWT' do
            header 'Accept', 'application/json'
            header 'Content-Type', 'application/json'
            post '/token', api_auth_data

            # Should respond with a 200
            expect(last_response.status).to eq(200)

            details = JSON.parse(last_response.body)

            expect(details.size).to eq(1)
            expect(details).to have_key('jwt')
          end
        end

        context 'via a trusted delegate and identity' do
          it 'provides a usable JWT' do
            header 'Accept', 'application/json'
            header 'Content-Type', 'application/json'
            header 'X-Authify-Access', RSpec.configuration.trusted_delegate.access_key
            header 'X-Authify-Secret', RSpec.configuration.trusted_delegate.secret_key
            post '/token', trusted_delegate_auth_data

            # Should respond with a 200
            expect(last_response.status).to eq(200)

            details = JSON.parse(last_response.body)

            expect(details.size).to eq(1)
            expect(details).to have_key('jwt')
          end
        end

        context 'when injecting custom payload data' do
          it 'provides a usable JWT with custom payload data' do
            header 'Accept', 'application/json'
            header 'Content-Type', 'application/json'
            post '/token', api_auth_with_custom_payload_data

            # Should respond with a 200
            expect(last_response.status).to eq(200)

            details = JSON.parse(last_response.body)

            expect(details.size).to eq(1)
            expect(details).to have_key('jwt')

            data = JWT.decode(details['jwt'], public_key, true, jwt_options)[0]
            expect(data).to have_key('custom')
            expect(data['custom']).to eq('foo' => 'bar')
          end
        end
      end
    end
  end
end
