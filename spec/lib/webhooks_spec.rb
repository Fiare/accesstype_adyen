# frozen_string_literal: true

require 'spec_helper'
require 'accesstype_adyen'
require 'accesstype_adyen/api'

describe AccesstypeAdyen::Management do
  let(:management) do
    credentials = { api_key: 'ADYEN_API_KEY', merchant_account: 'MERCHANT_ACCOUNT' }
    AccesstypeAdyen::Management.new(credentials: credentials, environment: 'sandbox')
  end

  describe '.credentials_valid?' do
    it 'returns true' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/paymentMethods')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '"paymentMethods": []',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(management.credentials_valid?).to eq true
    end

    it 'returns false' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/paymentMethods')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 400, body: '{"status": 400, "errorCode": "100", "message": "Some error message"}', headers: { 'Content-Type' => 'application/json' })

      expect(management.credentials_valid?).to eq false
    end
  end
end
