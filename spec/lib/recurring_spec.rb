# frozen_string_literal: true

require 'spec_helper'
require 'accesstype_adyen'
require 'accesstype_adyen/payment_result'
require 'accesstype_adyen/api'

describe AccesstypeAdyen::Recurring do
  let(:recurring_payment) do
    credentials = { 'api_key' => 'ADYEN_API_KEY', 'merchant_account' => 'MERCHANT_ACCOUNT' }
    AccesstypeAdyen::Recurring.new(credentials: credentials, environment: 'sandbox')
  end

  describe '.preview' do
    it 'should always return nil' do
      expect(recurring_payment.preview).to eq nil
    end
  end

  describe '.charge?' do
    it 'should always return false' do
      expect(recurring_payment.charge?).to eq false
    end
  end

  describe '.initiate_charge' do
    it 'returns payment result with success' do
      stub_request(:post, 'https://checkout-test.adyen.com/v67/payments')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '{
                "additionalData": {
                  "recurringProcessingModel": "Subscription",
                  "adjustAuthorisationData": "some_auth_data"
                },
                "pspReference": "863628593129097A",
                "resultCode": "Authorised",
                "amount": {
                  "currency": "EUR",
                  "value": 1200
                },
                "merchantReference": "some_order_number",
                "metadata": {
                  "attemptToken": "some_attempt_token"
                }
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
            amount_cents: 1200,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = recurring_payment.initiate_charge(payload: payload, subscription_plan: { id: 1002 }, subscriber: { id: 2003 })

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 1200
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
            amount_cents: 1300,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = recurring_payment.initiate_charge(payload: payload, subscription_plan: { id: 1002 }, subscriber: { id: 2003 })

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
              "merchantReference": "some_order_number",
              "metadata": {
                "attemptToken": "some_attempt_token"
              }
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
            amount_cents: 1400,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = recurring_payment.initiate_charge(payload: payload, subscription_plan: { id: 1002 }, subscriber: { id: 2003 })

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
            amount_cents: 1500,
            amount_currency: 'EUR'
          },
        },
        attempt_token: 'some_attempt_token',
        payment_token: 'some_payment_token'
      }

      result = recurring_payment.initiate_charge(payload: payload, subscription_plan: { id: 1002 }, subscriber: { id: 2003 })

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.after_charge' do
    it 'returns payment result with success without need for payment details' do
      payment = { payment_token: 'some_payment_token', amount_cents: 1600, amount_currency: 'EUR' }
      result = recurring_payment.after_charge(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_cents).to eq 1600
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
        payment_token: 'some_payment_token',
        amount_cents: 1700,
        amount_currency: 'EUR',
        additional_data:
          {
            is_payment_details_required: true,
            dropin_state_data: 'some_state_data',
            payment_data: 'some_payment_data'
          }
      }
      result = recurring_payment.after_charge(payment: payment)

      expect(result.success).to eq true
      expect(result.amount_currency).to eq 'EUR'
      expect(result.amount_cents).to eq 1700
      expect(result.payment_token).to eq 'some_payment_token'
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
        amount_cents: 1800,
        amount_currency: 'EUR',
        additional_data: { is_payment_details_required: true }
      }
      result = recurring_payment.after_charge(payment: payment)

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
        amount_cents: 1900,
        amount_currency: 'EUR',
        additional_data: { is_payment_details_required: true }
      }
      result = recurring_payment.after_charge(payment: payment)

      expect(result.success).to eq false
      expect(result.code).to eq '100'
      expect(result.message).to eq 'Received 100 - Some error message'
      expect(result.status).to eq 422
      expect(result.payload).to eq 'some_payment_token'
    end
  end

  describe '.cancel_subscription' do
    it 'returns payment result with success' do
      stub_request(:post, 'https://pal-test.adyen.com/pal/servlet/Recurring/v49/disable')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: '[all-details-successfully-disabled]',
          headers: { 'Content-Type' => 'application/text' }
        )

      payment = { external_payment_id: 'some_external_payment_id', amount_currency: 'EUR' }
      result = recurring_payment.cancel_subscription(payment: payment)

      expect(result.success).to eq true
      expect(result.message).to eq 'Subscription cancelled successfully'
    end

    it 'returns payment result with error' do
      stub_request(:post, 'https://pal-test.adyen.com/pal/servlet/Recurring/v49/disable')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 422,
          body: '{"status": 422, "errorCode": "100", "message": "Some error message"}',
          headers: { 'Content-Type' => 'application/json' }
        )

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
