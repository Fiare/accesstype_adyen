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
    # Expected params: payment object with payment_token, is_payment_details_required, opts
    # Returns: Payment result object
    def after_charge(payment:, is_payment_details_required: false, opts: nil)
      if is_payment_details_required
        response = Api.payment_details(credentials, opts)

        if response.code.to_i == 200
          if VALID_STATUSES.include?(response['resultCode'].to_s)
            payment_fee = response['splits']&.find_all { |split| split['type'] == 'PaymentFee' }&.first
            PaymentResult.success(
              AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
              payment_token: payload[:payment_token],
              payment_gateway_fee: !payment_fee.nil? ? payment_fee['amount']['value'] : nil,
              payment_gateway_fee_currency: !payment_fee.nil? ? payment_fee['amount']['currency'] || response['amount']['currency'] : nil,
              amount_currency: response['amount']['currency'].to_s,
              amount_cents: response['amount']['value'],
              status: response['resultCode']
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
      response = Api.cancel_recurring_subscription(credentials, payment[:subscriber_id])

      if response.code == 200 && VALID_SUBSCRIPTION_CANCEL_STATUSES.include?(response.to_s)
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
          message: 'Subscription cancelled successfully',
          status: response['status']
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
            AccesstypeAdyen::PAYMENT_GATEWAY,
            payment_token: payload[:payment_token],
            payment_gateway_fee: !payment_fee.nil? ? payment_fee['amount']['value'] : nil,
            payment_gateway_fee_currency: !payment_fee.nil? ? payment_fee['amount']['currency'] || response['amount']['currency'] : nil,
            amount_currency: !response['amount'].nil? ? response['amount']['currency'].to_s : nil,
            amount_cents: !response['amount'].nil? ? response['amount']['value'] : nil,
            status: response['resultCode']
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
