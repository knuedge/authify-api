require 'spec_helper'

# Tests for the /registration endpoints
describe Authify::API::Services::Registration do
  include Rack::Test::Methods

  def app
    Authify::API::Services::Registration
  end

  context 'mounted at /registration' do
    # /signup
    context 'signup endpoint' do
      let(:password_signup_data) do
        {
          'email'    => 'second.user@example.com',
          'password' => 'seconduser1234'
        }
      end

      let(:identity_signup_data) do
        {
          'email'    => 'third.user@example.com',
          'via' => {
            'provider' => 'facetube',
            'uid'      => '23456'
          }
        }
      end

      context 'POST /signup' do
        it 'allows registration via email and password' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          post '/signup', password_signup_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(3)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(false)
          expect(details['email']).to eq(password_signup_data['email'])
          expect(details['id']).to eq(4)
        end

        it 'allows registration via delegate and identity' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          header 'X-Authify-Access', RSpec.configuration.trusted_delegate.access_key
          header 'X-Authify-Secret', RSpec.configuration.trusted_delegate.secret_key
          post '/signup', identity_signup_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(4)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(true)
          expect(details).to have_key('jwt')
          expect(details['email']).to eq(identity_signup_data['email'])
          expect(details['id']).to eq(5)
        end
      end
    end
  end
end