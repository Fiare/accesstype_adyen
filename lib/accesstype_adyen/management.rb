# frozen_string_literal: true

module AccesstypeAdyen
  # Used for calling several other apis of razorpay
  # which are not required for payment but it would be
  # required by accesstype for managing other stuff.
  class Management
    attr_accessor :api_key, :merchant_account, :environment

    def initialize(credentials:, environment:)
      @api_key = credentials[:api_key]
      @merchant_account = credentials[:merchant_account]
      @environment = environment || 'live'
    end

    # Used for validating whether given credentials are valid or not.
    #
    # Expected params: none
    # Returns: boolean
    def credentials_valid?
      return false if api_key.nil? || merchant_account.nil?

      response = Api.validate_credentials(credentials)
      response.code == 200
    end

    private

    def credentials
      { api_key: api_key, merchant_account: merchant_account, environment: environment }
    end
  end
end
