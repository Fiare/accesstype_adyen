# frozen_string_literal: true

module AccesstypeAdyen
  # Used for calling one time payment methods of adyen.
  class Onetime
    attr_accessor :api_key, :merchant_account, :environment

    def initialize(credentials:, environment:)
      @api_key = credentials[:api_key]
      @merchant_account = credentials[:merchant_account]
      @environment = environment || 'live'
    end

    # This method will return nil by default. We can't do anything without payment to Adyen.
    #
    # Expected params: any
    # Returns: nil
    def preview(*)
      nil
    end

    # This method will return payment can be capture or not.
    # This method will be called before calling the capture method to check the class supports capture method or not
    #
    # Expected params: none
    # Returns: true
    def capture?
      true
    end

    # Used for fetching payment based on payment token,
    # but that is not possible with Adyen. Instead,
    # payment is marked as successful. Make sure you
    # check payment response before calling this method.
    #
    # Expected params: payment object with payment_token
    # Returns: Payment Result object
    def after_charge(payment:)
      if !payment[:additional_data].nil? && payment.dig(:additional_data, :is_payment_details_required).to_s.downcase == 'true'
        state_data = payment.dig(:additional_data, :details)
        payment_data = payment.dig(:additional_data, :payment_data)

        response = Api.payment_details(credentials, state_data, payment_data)

        if response.code.to_i == 200
          if VALID_STATUSES.include?(response['resultCode'].to_s)
            PaymentResult.success(
              AccesstypeAdyen::PAYMENT_GATEWAY,
              payment_token: response['pspReference'],
              amount_currency: payment[:amount_currency].to_s,
              amount_cents: payment[:amount_cents],
              external_payment_id: response['pspReference'],
              status: response['resultCode'],
              client_payload: response
            )
          else
            error_response(
              response['refusalReasonCode'],
              response['refusalReason'],
              response['resultCode'],
              payment[:payment_token]
            )
          end
        else
          error_response(
            response['errorCode'],
            response['message'],
            response['status'],
            payment[:payment_token]
          )
        end
      else
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_GATEWAY,
          payment_token: payment[:payment_token],
          amount_currency: payment[:amount_currency].to_s,
          amount_cents: payment[:amount_cents]
        )
      end
    end

    # Used for capturing payment from Adyen.
    #
    # Expected params: payment object with token, amount and currency
    # Returns: Payment Result object
    def capture(payment:)
      response = Api.capture_payment(
        credentials,
        payment["payment_token"],
        payment["amount_cents"],
        payment["amount_currency"].to_s
      )

      if response.code.to_i == 201
        payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_GATEWAY,
          payment_token: payment[:payment_token],
          payment_gateway_fee: 0,
          payment_gateway_fee_currency: response['amount']['currency'],
          amount_currency: response['amount']['currency'].to_s,
          amount_cents: response['amount']['value'],
          external_capture_id: response['pspReference'],
          status: response['status']
        )
      else
        error_response(response['errorCode'], response['message'], response['status'], payment[:payment_token])
      end
    end

    # Used for refunding payment from Adyen.
    #
    # Expected params: invoice object, amount
    # Returns: Payment Result object
    def refund_payment(invoice:, amount:)
      response = Api.refund_payment(
        credentials,
        invoice["external_payment_id"],
        invoice["amount_currency"],
        amount
      )

      if response.code == 201
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_GATEWAY,
          external_refund_id: response['pspReference'],
          amount_currency: response['amount']['currency'].to_s,
          amount_cents: response['amount']['value'],
          status: response['status']
        )
      else
        error_response(response['errorCode'], response['message'], response['status'], invoice[:external_payment_id])
      end
    end

    # This method will initiate the payment and return either
    # "Authorised" or "RedirectShopper" as a status, depending
    # if redirect is needed or not. Redirect response and sending
    # the details to the payment gateway are handled in the
    # after_charge method
    #
    # Expected params: payload
    # Returns: Payment result object
    def initiate_charge(payload:, subscription_plan:, subscriber:)
      response = Api.charge_onetime(
        credentials,
        payload
      )

      if response.code.to_i == 200
        if VALID_STATUSES.include?(response['resultCode'].to_s)
          payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
          PaymentResult.success(
            AccesstypeAdyen::PAYMENT_GATEWAY,
            payment_token: payload[:payment_token],
            payment_gateway_fee: !payment_fee.nil? ? payment_fee['amount']['value'] : nil,
            payment_gateway_fee_currency: !payment_fee.nil? ? payment_fee['amount']['currency'] || response['amount']['currency'] : nil,
            amount_currency: !response['amount'].nil? ? response['amount']['currency'].to_s : nil,
            amount_cents: !response['amount'].nil? ? response['amount']['value'] : nil,
            metadata: !response['action'].nil? ? response['action']['paymentData'] : nil,
            status: response['resultCode'],
            client_payload: response
          )
        else
          error_response(
            response['refusalReasonCode'],
            response['refusalReason'],
            response['resultCode'],
            payload[:payment_token]
          )
        end
      else
        error_response(
          response['errorCode'],
          response['message'],
          response['status'],
          payload[:payment_token]
        )
      end
    end

    def error_response(code, description, status, payload = nil)
      PaymentResult.error(
        AccesstypeAdyen::PAYMENT_GATEWAY,
        code: code,
        message: "Received #{code} - #{description}",
        status: status,
        payload: payload
      )
    end

    def credentials
      { api_key: api_key, merchant_account: merchant_account, environment: environment }
    end
  end
end
