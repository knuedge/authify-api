module Authify
  module API
    module Services
      # The monitoring application
      class Monitoring < Service
        configure do
          set :protection, except: :http_origin
        end

        before do
          content_type 'application/json'

          begin
            unless request.get? || request.options?
              request.body.rewind
              @parsed_body = JSON.parse(request.body.read, symbolize_names: true)
            end
          rescue => e
            halt(400, { error: "Request must be valid JSON: #{e.message}" }.to_json)
          end
        end

        after do
          headers 'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => %w[OPTIONS GET POST],
                  'Access-Control-Allow-Headers' => %w[
                    Origin
                    Accept
                    Accept-Encoding
                    Accept-Language
                    Access-Control-Request-Headers
                    Access-Control-Request-Method
                    Authorization
                    Connection
                    Content-Type
                    Host
                    Referer
                    User-Agent
                    X-Requested-With
                    X-Forwarded-For
                    X-XSRF-Token
                  ]
        end

        # Provide information about the JWTs generated by the server
        get '/info' do
          metrics = Metrics.instance
          output = {}
          metrics.each do |key, value|
            output[key] = value
          end
          output.to_json
        end

        options '/info' do
          halt 200
        end
      end
    end
  end
end
