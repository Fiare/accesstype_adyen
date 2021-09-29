# frozen_string_literal: true

module AccesstypeAdyen
  # Used for calling recurring payment methods of adyen.
  class Recurring
    attr_accessor :api_key, :merchant_account, :environment

    def initialize(credentials:, environment:)
      @api_key = credentials[:api_key]
      @merchant_account = credentials[:merchant_account]
      @environment = environment || 'live'
    end

    # This method will return nil by default.
    # We can't do anything without creating an order.
    #
    # Expected params: any
    # Returns: nil
    def preview(*)
      nil
    end

    # This method will return true if the class has charge method.
    # It will return false if the class hasn't charge method.
    #
    # Returns: boolean
    def charge?
      false
    end

    def capture?
      true
    end

    # @note For Adyen, this method is replaced by the initiate_charge method
    #
    # This is not a mandatory method. However, This method needs to be created in payment
    # adapter gem when we need to call API for making payment based on the card details.
    #
    # Expected params: payload, subscription_attempt
    # Returns: Payment result object
    # def charge(payload:, subscription_plan:, subscriber:)
    #   response = Api.charge_recurring_subscription(
    #     credentials,
    #     payload,
    #     subscription_plan,
    #     subscriber
    #   )
    #
    #   if response.code.to_i == 200
    #     if VALID_STATUSES.include?(response['resultCode'].to_s)
    #       payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
    #       PaymentResult.success(
    #         AccesstypeAdyen::PAYMENT_GATEWAY,
    #         payment_token: payload[:payment_token],
    #         payment_gateway_fee: !payment_fee.nil? ? payment_fee['amount']['value'] : nil,
    #         payment_gateway_fee_currency: !payment_fee.nil? ? payment_fee['amount']['currency'] || response['amount']['currency'] : nil,
    #         amount_currency: response['amount']['currency'].to_s,
    #         amount_cents: response['amount']['value'],
    #         status: response['resultCode']
    #       )
    #     else
    #       error_response(
    #         response['refusalReasonCode'],
    #         response['refusalReason'],
    #         response['resultCode'],
    #         payload[:payment_token]
    #       )
    #     end
    #   else
    #     error_response(
    #       response['errorCode'],
    #       response['message'],
    #       response['status'],
    #       payload[:payment_token]
    #     )
    #   end
    # end

    # Used for fetching subscription and verifying
    # if the subscription is valid, but that is not
    # possible with Adyen. Instead, payment is marked
    # as successful. Make sure you check payment
    # response before calling this method.
    #
    # Expected params: payment object with payment_token
    # Returns: Payment result object
    def after_charge(payment:)
      if !payment[:additional_data].nil? && payment.dig(:additional_data,
                                                        :is_payment_details_required).to_s.downcase == 'true'

        state_data = payment.dig(:additional_data, :details)
        payment_data = payment.dig(:additional_data, :payment_data)

        response = Api.payment_details(credentials, state_data, payment_data)

        if response.code.to_i == 200
          if VALID_STATUSES.include?(response['resultCode'].to_s)
            PaymentResult.success(
              AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
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
          AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
          payment_token: payment[:payment_token],
          amount_cents: payment[:amount_cents],
          amount_currency: payment[:amount_currency].to_s
        )
      end
    end

    # Used for cancelling subscription. If the cancellation is
    # successful, the method will return a success struct with success = true
    # Else the method will return an error struct, with success = false
    #
    # Expected params: payment object with subscriber_id
    # Returns: Payment result object
    def cancel_subscription(payment:)
      response = Api.cancel_recurring_subscription(credentials, payment)

      if response.code == 200 && VALID_SUBSCRIPTION_CANCEL_STATUSES.include?(response['response'])
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
          message: 'Subscription cancelled successfully',
          status: response['response']
        )
      else
        error_response(
          response['errorCode'],
          response['message'],
          response['status'],
          payment[:payment_token]
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
        payment['payment_token'],
        payment['amount_cents'],
        payment['amount_currency'].to_s
      )

      if response.code.to_i == 201
        payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
          payment_token: payment[:payment_token],
          payment_gateway_fee: !payment_fee.nil? ? payment_fee['amount']['value'] : nil,
          payment_gateway_fee_currency: !payment_fee.nil? ? payment_fee['amount']['currency'] || response['amount']['currency'] : nil,
          amount_currency: response['amount']['currency'].to_s,
          amount_cents: response['amount']['value'],
          external_capture_id: response['pspReference'],
          status: response['status']
        )
      else
        error_response(response['errorCode'], response['message'], response['status'], payment[:payment_token])
      end
    end

    def recurring_detail_reference(subscriber_id)
      response = Api.recurring_detail_reference(
        credentials,
        subscriber_id
      )

      if response.code.to_i == 200 && !response['details'].nil?

        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
          payload: response
        )

      elsif response.code.to_i == 200
        error_response(
          nil,
          'Subscription already cancelled',
          'CANCELLED'
        )

      else
        error_response(
          response['errorCode'],
          response['message'],
          response['status']
        )
      end
    end

    # This method will initiate the payment and return either
    # "Authorised" or "RedirectShopper" as a status, depending
    # if redirect is needed or not. Redirect response and sending
    # the details to the payment gateway are handled in the
    # after_charge method
    #
    # Expected params: payload, subscription_plan, subscriber
    # Returns: Payment result object
    def initiate_charge(payload:, subscription_plan:, subscriber:)
      response = Api.charge_recurring_subscription(
        credentials,
        payload,
        subscription_plan,
        subscriber
      )

      if response.code.to_i == 200
        if VALID_STATUSES.include?(response['resultCode'].to_s)
          payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
          PaymentResult.success(
            AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
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

    def recurring_payment(payload:)
      response = Api.recurring_payment(
        credentials,
        payload
      )

      if response.code.to_i == 200
        if VALID_STATUSES.include?(response['resultCode'].to_s)
          payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
          PaymentResult.success(
            AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
            payment_token: response["pspReference"],
            payment_gateway_fee: !payment_fee.nil? ? payment_fee['amount']['value'] : nil,
            payment_gateway_fee_currency: !payment_fee.nil? ? payment_fee['amount']['currency'] || response['amount']['currency'] : nil,
            amount_currency: !response['amount'].nil? ? response['amount']['currency'].to_s : nil,
            amount_cents: !response['amount'].nil? ? response['amount']['value'] : nil,
            status: response['resultCode'],
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
        AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
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
