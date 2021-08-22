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

  describe '.initiate_charge' do
    it 'returns payment result with success' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
                "additionalData": {},
                "pspReference": "863628593129097A",
                "resultCode": "Authorised",
                "amount": {
                  "currency": "EUR",
                  "value": 6700
                },
                "merchantReference": "some_order_number"
              }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = { payment_token: 'some_payment_token', amount_cents: 6700, amount_currency: 'EUR' }

      result = onetime_payment.initiate_charge(payload: payload)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 6700
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
    end
    it 'returns payment result with redirect' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
            "resultCode": "RedirectShopper",
            "action": {
              "paymentMethodType": "ideal",
              "url": "https://checkoutshopper-test.adyen.com/checkoutshopper/checkoutPaymentRedirect?redirectData=some_redirect_data",
              "method": "GET",
              "type": "redirect"
            }
          }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = { payment_token: 'some_payment_token', amount_cents: 6700, amount_currency: 'EUR' }

      result = onetime_payment.initiate_charge(payload: payload)

      expect(result.success).to eq true
      expect(result.status).to eq 'RedirectShopper'
      expect(result.payment_token).to eq 'some_payment_token'
    end
    it 'returns error payment result with resultCode and refusalReason' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
              "pspReference": "883628594626593C",
              "refusalReason": "Expired Card",
              "resultCode": "Refused",
              "refusalReasonCode": "6",
              "merchantReference": "some_order_number"
            }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = { payment_token: 'some_payment_token', amount_cents: 6700, amount_currency: 'EUR' }

      result = onetime_payment.initiate_charge(payload: payload)

      expect(result.success).to eq false
      expect(result.code).to eq '6'
      expect(result.message).to eq 'Received 6 - Expired Card'
      expect(result.status).to eq 'Refused'
      expect(result.payload).to eq 'some_payment_token'
    end

    it 'returns error payment result with errorCode and message' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = { payment_token: 'some_payment_token', amount_cents: 6700, amount_currency: 'EUR' }

      result = onetime_payment.initiate_charge(payload: payload)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.after_charge' do
    it 'returns payment result with success' do
      payment = { payment_token: 'some_payment_token', amount_cents: 5000, amount_currency: 'EUR' }
      result = onetime_payment.after_charge(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 5000
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
    end

    it 'returns error payment result with resultCode and refusalReason' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
              "pspReference": "883628594626593C",
              "refusalReason": "Expired Card",
              "resultCode": "Refused",
              "refusalReasonCode": "6",
              "merchantReference": "some_order_number"
            }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = { payment_token: 'some_payment_token', amount_cents: 6700, amount_currency: 'EUR' }

      result = onetime_payment.initiate_charge(payload: payload)

      expect(result.success).to eq false
      expect(result.code).to eq '6'
      expect(result.message).to eq 'Received 6 - Expired Card'
      expect(result.status).to eq 'Refused'
      expect(result.payload).to eq 'some_payment_token'
    end

    it 'returns error payment result with errorCode and message' do
      stub_request(:post, 'https://checkout-test.adyen.com/checkout/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = { payment_token: 'some_payment_token', amount_cents: 6700, amount_currency: 'EUR' }

      result = onetime_payment.initiate_charge(payload: payload)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.capture' do
    it 'returns payment result with success' do
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

    it 'returns payment result with error' do
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
    it 'returns payment result with success' do
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

    it 'returns payment result with error' do
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
