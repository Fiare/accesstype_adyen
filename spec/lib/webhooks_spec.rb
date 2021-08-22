# frozen_string_literal: true

require 'ostruct'
require 'spec_helper'
require 'accesstype_adyen'
require 'accesstype_adyen/api'

describe AccesstypeAdyen::Webhooks do
  let(:webhooks) do
    credentials = { api_key: 'ADYEN_API_KEY', hmac_key: '44782DEF547AAA06C910C43932B1EB0C71FC68D9D0C057550C48EC2ACF6BA056', merchant_account: 'MERCHANT_ACCOUNT' }
    AccesstypeAdyen::Webhooks.new(credentials: credentials, environment: 'sandbox')
  end

  describe '.webhook_request_authorized?' do
    it 'returns true for valid hmacSignature' do
      request = OpenStruct.new(
        {
          body: '{
             "live":"false",
             "notificationItems":[
                {
                   "NotificationRequestItem":{
                      "additionalData":{
                         "hmacSignature":"coqCmt/IZ4E3CzPvMY8zTjQVL5hYJUiBRg8UU+iCWo0="
                      },
                      "amount":{
                         "value":1130,
                         "currency":"EUR"
                      },
                      "pspReference":"7914073381342284",
                      "eventCode":"AUTHORISATION",
                      "eventDate":"2019-05-06T17:15:34.121+02:00",
                      "merchantAccountCode":"TestMerchant",
                      "operations":[
                         "CANCEL",
                         "CAPTURE",
                         "REFUND"
                      ],
                      "merchantReference":"TestPayment-1407325143704",
                      "paymentMethod":"visa",
                      "success":"true"
                   }
                }
             ]
          }'
        }
      )

      expect(webhooks.webhook_request_authorized?(request: request)).to eq true
    end

    it 'returns false for invalid hmacSignature' do
      request = OpenStruct.new(
        {
          body: '{
             "live":"false",
             "notificationItems":[
                {
                   "NotificationRequestItem":{
                      "additionalData":{
                         "hmacSignature":"something_false"
                      },
                      "amount":{
                         "value":1130,
                         "currency":"EUR"
                      },
                      "pspReference":"7914073381342284",
                      "eventCode":"AUTHORISATION",
                      "eventDate":"2019-05-06T17:15:34.121+02:00",
                      "merchantAccountCode":"TestMerchant",
                      "operations":[
                         "CANCEL",
                         "CAPTURE",
                         "REFUND"
                      ],
                      "merchantReference":"TestPayment-1407325143704",
                      "paymentMethod":"visa",
                      "success":"true"
                   }
                }
             ]
          }'
        }
      )

      expect(webhooks.webhook_request_authorized?(request: request)).to eq false
    end

    it 'returns false for missing hmacSignature' do
      request = request = OpenStruct.new(
        {
          body: '{
             "live":"false",
             "notificationItems":[]
          }'
        }
      )

      expect(webhooks.webhook_request_authorized?(request: request)).to eq false
    end
  end

  describe '.webhook_event_type_mapping' do
    it 'returns supported webhook events' do
      events = webhooks.webhook_event_type_mapping
      expect(events['AUTHORISATION']).to eq 'one_time_subscription_charged'
      # expect(events['subscription.charged']).to eq 'recurring_subscription_charged'
      # expect(events['subscription.halted']).to eq 'recurring_subscription_cancelled'
      # expect(events['subscription.cancelled']).to eq 'recurring_subscription_cancelled'
    end
  end

  describe '.webhook_event_details' do
    it 'returns webhook event details' do
      payload = {
        "live": "false",
        "notificationItems": [
          {
            "NotificationRequestItem": {
              "additionalData": {
                "shopperEmail": "s.hopper@adyen.com",
                "shopperReference": "some_shopper_reference",
              },
              "eventCode": "AUTHORISATION",
              "success": "true",
              "eventDate": "2019-06-28T18:03:50+01:00",
              "merchantAccountCode": "some_merchant_account",
              "pspReference": "7914073381342284",
              "merchantReference": "some_merchant_reference",
              "amount": {
                "value": 1130,
                "currency": "EUR"
              }
            }
          },
          {
            "NotificationRequestItem": {
              "additionalData": {
                "recurring.recurringDetailReference": "9915692881181044",
                "recurring.shopperReference": "other_shopper_reference"
              },
              "eventCode": "CANCELLATION",
              "success": "false",
              "eventDate": "2019-06-28T18:03:50+01:00",
              "merchantAccountCode": "other_merchant_account",
              "pspReference": "9854378374932723",
              "merchantReference": "other_merchant_reference",
              "amount": {
                "value": 3310,
                "currency": "EUR"
              }
            }
          },
          {
            "NotificationRequestItem": {
              "additionalData": {},
              "eventCode": "REFUND_REVERSED",
              "success": "true",
              "eventDate": "2019-06-28T18:03:50+01:00",
              "merchantAccountCode": "other_merchant_account",
              "pspReference": "8954898327248374",
              "merchantReference": "other_merchant_reference",
              "amount": {
                "value": 4420,
                "currency": "EUR"
              },
              "splits": [
                {
                  "type": "PaymentFee",
                  "amount": {
                    "value": 1000,
                    "currency": "EUR"
                  }
                }
              ]
            }
          }
        ]
      }

      expected_responses = [
        {
          attempt_token: nil,
          amount_currency: "EUR",
          amount_cents: 1130,
          status: "Success",
          external_payment_id: "7914073381342284",
          email: "s.hopper@adyen.com",
          contact: nil,
          event: "AUTHORISATION",
          external_subscription_id: nil,
          payment_gateway_fee_cents: nil,
          payment_gateway_fee_currency: nil
        },
        {
          attempt_token: nil,
          amount_currency: "EUR",
          amount_cents: 3310,
          status: "Failure",
          external_payment_id: "9854378374932723",
          email: nil,
          contact: nil,
          event: "CANCELLATION",
          external_subscription_id: "9915692881181044",
          payment_gateway_fee_cents: nil,
          payment_gateway_fee_currency: nil
        },
        {
          attempt_token: nil,
          amount_currency: "EUR",
          amount_cents: 4420,
          status: "Success",
          external_payment_id: "8954898327248374",
          email: nil,
          contact: nil,
          event: "REFUND_REVERSED",
          external_subscription_id: nil,
          payment_gateway_fee_cents: 1000,
          payment_gateway_fee_currency: "EUR"
        }
      ]

      expect(webhooks.webhook_event_details(payload: payload[:notificationItems][0])).to eq expected_responses[0]
      expect(webhooks.webhook_event_details(payload: payload[:notificationItems][1])).to eq expected_responses[1]
      expect(webhooks.webhook_event_details(payload: payload[:notificationItems][2])).to eq expected_responses[2]
    end
  end
end
