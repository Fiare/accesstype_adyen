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
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
                "additionalData": {},
                "pspReference": "863628593129097A",
                "resultCode": "Authorised",
                "amount": {
                  "currency": "EUR",
                  "value": 2200
                },
                "merchantReference": "some_order_number"
              }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = {
        subscription: {
          additional_data: {
            dropin_state_data: {
              paymentMethod: {
                type: 'scheme',
                encryptedCardNumber: 'test_4111111111111111',
                encryptedExpiryMonth: 'test_03',
                encryptedExpiryYear: 'test_2030',
                encryptedSecurityCode: 'test_737'
              },
              browserInfo: {
                userAgent: 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0',
                acceptHeader: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
              },
              origin: 'some_origin'
            },
            return_url: 'https://www.example.com',
          },
          payment: {
            amount_cents: 2200,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = onetime_payment.initiate_charge(payload: payload, subscription_plan: nil, subscriber: nil)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 2200
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
    end
    it 'returns payment result with redirect' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
            "resultCode": "RedirectShopper",
            "action": {
              "data": {},
              "method": "POST",
              "paymentData": "some_payment_data",
              "paymentMethodType": "scheme",
              "type": "redirect",
              "url": "https://test.adyen.com/hpp/3d/validate.shtml"
            },
            "details": []
          }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = {
        subscription: {
          additional_data: {
            dropin_state_data: {
              paymentMethod: {
                type: 'scheme',
                encryptedCardNumber: 'test_4111111111111111',
                encryptedExpiryMonth: 'test_03',
                encryptedExpiryYear: 'test_2030',
                encryptedSecurityCode: 'test_737'
              },
              browserInfo: {
                userAgent: 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0',
                acceptHeader: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
              },
              origin: 'some_origin'
            },
            return_url: 'https://www.example.com',
          },
          payment: {
            amount_cents: 2300,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = onetime_payment.initiate_charge(payload: payload, subscription_plan: nil, subscriber: nil)

      expect(result.success).to eq true
      expect(result.status).to eq 'RedirectShopper'
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.metadata).to eq 'some_payment_data'
    end
    it 'returns error payment result with resultCode and refusalReason' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments')
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

      payload = {
        subscription: {
          additional_data: {
            dropin_state_data: {
              paymentMethod: {
                type: 'scheme',
                encryptedCardNumber: 'test_4111111111111111',
                encryptedExpiryMonth: 'test_03',
                encryptedExpiryYear: 'test_2030',
                encryptedSecurityCode: 'test_737'
              },
              browserInfo: {
                userAgent: 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0',
                acceptHeader: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
              },
              origin: 'some_origin'
            },
            return_url: 'https://www.example.com',
          },
          payment: {
            amount_cents: 2400,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = onetime_payment.initiate_charge(payload: payload, subscription_plan: nil, subscriber: nil)

      expect(result.success).to eq false
      expect(result.code).to eq '6'
      expect(result.message).to eq 'Received 6 - Expired Card'
      expect(result.status).to eq 'Refused'
      expect(result.payload).to eq 'some_payment_token'
    end

    it 'returns error payment result with errorCode and message' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      payload = {
        subscription: {
          additional_data: {
            dropin_state_data: {
              paymentMethod: {
                type: 'scheme',
                encryptedCardNumber: 'test_4111111111111111',
                encryptedExpiryMonth: 'test_03',
                encryptedExpiryYear: 'test_2030',
                encryptedSecurityCode: 'test_737'
              },
              browserInfo: {
                userAgent: 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9) Gecko/2008052912 Firefox/3.0',
                acceptHeader: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
              },
              origin: 'some_origin'
            },
            return_url: 'https://www.example.com',
          },
          payment: {
            amount_cents: 2500,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = onetime_payment.initiate_charge(payload: payload, subscription_plan: nil, subscriber: nil)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.after_charge' do
    it 'returns payment result with success without need for payment details' do
      payment = { payment_token: 'some_payment_token', amount_cents: 2600, amount_currency: 'EUR' }
      result = onetime_payment.after_charge(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 2600
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
    end

    it 'returns payment result with success with payment details' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/details')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
            "pspReference": "88154795347618C",
            "resultCode": "Authorised"
          }',
          headers: { 'Content-Type' => 'application/json' }
        )

      payment = {
        amount_cents: 2700,
        amount_currency: 'EUR',
        additional_data:
          {
            is_payment_details_required: true,
            dropin_state_data: 'some_state_data',
            payment_data: 'some_payment_data'
          }
      }
      result = onetime_payment.after_charge(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_currency).to eq 'EUR'
      expect(result.amount_cents).to eq 2700
      expect(result.payment_token).to eq '88154795347618C'
      expect(result.external_payment_id).to eq '88154795347618C'
    end

    it 'returns error payment result with resultCode and refusalReason' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/details')
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

      payment = {
        payment_token: 'some_payment_token',
        amount_cents: 2800,
        amount_currency: 'EUR',
        additional_data: { is_payment_details_required: true }
      }
      result = onetime_payment.after_charge(payment: payment)

      expect(result.success).to eq false
      expect(result.code).to eq '6'
      expect(result.message).to eq 'Received 6 - Expired Card'
      expect(result.status).to eq 'Refused'
      expect(result.payload).to eq 'some_payment_token'
    end

    it 'returns error payment result with errorCode and message' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/details')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      payment = {
        payment_token: 'some_payment_token',
        amount_cents: 2900,
        amount_currency: 'EUR',
        additional_data: { is_payment_details_required: true }
      }
      result = onetime_payment.after_charge(payment: payment)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.capture' do
    it 'returns payment result with success' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/some_payment_token/captures')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
            "amount": { "currency": "EUR", "value": 3000 },
            "status": "received"
          }',
          headers: { 'Content-Type' => 'application/json' })

      payment = { payment_token: 'some_payment_token', amount_cents: 3000, amount_currency: 'EUR' }
      result = onetime_payment.capture(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 3000
      expect(result.payment_token).to eq 'some_payment_token'
      expect(result.amount_currency).to eq 'EUR'
      expect(result.status).to eq 'received'
    end

    it 'returns payment result with error' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/some_payment_token/captures')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 422, body: '{"status": 422, "errorCode": "100", "message": "Some error message"}', headers: { 'Content-Type' => 'application/json' })

      payment = { payment_token: 'some_payment_token', amount_cents: 3100, amount_currency: 'EUR' }
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
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/some_external_payment_id/refunds')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
            "amount": {"currency": "EUR", "value": 3200},
            "merchantAccount": "some_merchant_account",
            "paymentPspReference": "some_payment_reference",
            "pspReference": "some_reference",
            "status": "received"
          }',
          headers: { 'Content-Type' => 'application/json' })

      invoice = { external_payment_id: 'some_external_payment_id', amount_currency: 'EUR' }
      result = onetime_payment.refund_payment(invoice: invoice, amount: 3200)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 3200
      expect(result.external_refund_id).to eq 'some_payment_reference'
      expect(result.amount_currency).to eq 'EUR'
      expect(result.status).to eq 'received'
    end

    it 'returns payment result with error' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments/some_external_payment_id/refunds')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' })

      invoice = { external_payment_id: 'some_external_payment_id', amount_currency: 'EUR' }
      result = onetime_payment.refund_payment(invoice: invoice, amount: 3300)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_external_payment_id'
    end
  end
end
