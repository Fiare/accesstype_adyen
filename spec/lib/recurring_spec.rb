# frozen_string_literal: true

require 'spec_helper'
require "accesstype_adyen"
require "accesstype_adyen/payment_result"
require "accesstype_adyen/api"

describe AccesstypeAdyen::Recurring do
  let(:recurring_payment) do
    credentials = { api_key: 'ADYEN_API_KEY', merchant_account: 'MERCHANT_ACCOUNT' }
    AccesstypeAdyen::Recurring.new(credentials: credentials, environment: 'sandbox')
  end

  describe '.preview' do
    it 'should always return nil' do
      expect(recurring_payment.preview).to eq nil
    end
  end

  describe '.after_charge' do
    it 'returns success payment result' do
      payment = { payment_token: 'some_payment_token', amount_cents: 5000, amount_currency: 'EUR' }
      result = recurring_payment.after_charge(payment: payment)
      expect(result.success).to eq true
      expect(result.amount_cents).to eq 5000
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
    end
  end

  describe ".cancel_subscription" do
    it 'returns success payment result' do
      stub_request(:post, 'https://pal-test.adyen.com/pal/servlet/Recurring/v49/disable')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '[all-details-successfully-disabled]',
          headers: { 'Content-Type' => 'application/text' })

      payment = { external_payment_id: 'some_external_payment_id', amount_currency: 'EUR' }
      result = recurring_payment.cancel_subscription(payment: payment)

      expect(result.success).to eq true
      expect(result.message).to eq 'Subscription cancelled successfully'
    end

    it 'returns error payment result' do
      stub_request(:post, 'https://pal-test.adyen.com/pal/servlet/Recurring/v49/disable')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' })

      payment = { payment_token: 'some_payment_token' }
      result = recurring_payment.cancel_subscription(payment: payment)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end
end
