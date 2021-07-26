# frozen_string_literal: true

require 'httparty'

module AccesstypeAdyen
  # Used for calling Adyen PG API based on different request method.
  class ApiClient
    attr_reader :config, :credentials

    def initialize(config, credentials)
      @config = config
      @credentials = credentials
    end

    # Used for all the POST APIs of adyen
    def post(path, type, options)
      response = HTTParty.post(
        root_url(type) + path,
        headers: {
          'X-Api-Key' => api_key.to_s,
          'Content-Type' => 'application/json'
        },
        body: options
      )

      return response unless response.code >= 500

      raise BadGatewayError.new(
        gateway: AccesstypeAdyen::PAYMENT_GATEWAY,
        path: path,
        response_code: response.code,
        response_body: response.parsed_response
      )
    end

    def root_url(type)
      config[type][:root_url]
    end

    def api_key
      credentials[:api_key]
    end
  end
end
