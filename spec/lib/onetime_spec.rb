# frozen_string_literal: true

require 'spec_helper'
require 'accesstype_adyen'
require 'accesstype_adyen/payment_result'
require 'accesstype_adyen/api'

describe AccesstypeAdyen::Onetime do
  let(:onetime_payment) do
    credentials = { api_key: 'ADYEN_API_KEY', merchant_account: 'MERCHANT_ACCOUNT' }
    AccesstypeAdyen::Onetime.new(credentials: credentials, environment: 'sandbox')
  end

  describe '.preview' do
    it 'should always return nil' do
      expect(onetime_payment.preview).to eq nil
    end
  end

  describe '.capture?' do
    it 'should always return true' do
      expect(onetime_payment.capture?).to eq true
    end
  end

  describe '.after_charge' do
    it 'returns success payment result' do
      payment = { payment_token: 'some_payment_token', amount_cents: 5000, amount_currency: 'EUR' }
      result = onetime_payment.after_charge(payment: payment)
      expect(result.success).to eq true
      expect(result.amount_cents).to eq 5000
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
    end
  end

  describe '.capture' do
    it 'returns success payment result' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments/some_payment_token/captures')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{"amount": {"currency": "EUR", "value": 6000}, "status": "received"}', headers: { 'Content-Type' => 'application/json' })

      payment = { payment_token: 'some_payment_token', amount_cents: 6000, amount_currency: 'EUR' }
      result = onetime_payment.capture(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 6000
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
      expect(result.status).to eq 'received'
    end

    it 'returns error payment result' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments/some_payment_token/captures')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 422, body: '{"status": 422, "errorCode": "100", "message": "Some error message"}', headers: { 'Content-Type' => 'application/json' })

      payment = { payment_token: 'some_payment_token', amount_cents: 6000, amount_currency: 'EUR' }
      result = onetime_payment.capture(payment: payment)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.refund_payment' do
    it 'returns success payment result' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments/some_external_payment_id/refunds')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
            "amount": {"currency": "EUR", "value": 3000},
            "merchantAccount": "some_merchant_account",
            "paymentPspReference": "some_payment_reference",
            "pspReference": "some_reference",
            "status": "received"
          }',
          headers: { 'Content-Type' => 'application/json' })

      invoice = { external_payment_id: 'some_external_payment_id', amount_currency: 'EUR' }
      result = onetime_payment.refund_payment(invoice: invoice, amount: 3000)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 3000
      expect(result.external_refund_id).to eq 'some_payment_reference'
      expect(result.amount_currency).to eq 'EUR'
      expect(result.status).to eq 'received'
    end

    it 'returns error payment result' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments/some_external_payment_id/refunds')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' })

      invoice = { external_payment_id: 'some_external_payment_id', amount_currency: 'EUR' }
      result = onetime_payment.refund_payment(invoice: invoice, amount: 3000)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_external_payment_id'
    end
  end
end
