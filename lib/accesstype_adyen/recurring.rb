# frozen_string_literal: true

module AccesstypeAdyen
  # Used for calling recurring payment methods of adyen.
  class Recurring
    attr_accessor :api_key, :merchant_account, :environment

    def initialize(credentials:, environment:)
      @api_key = credentials['api_key']
      @merchant_account = credentials['merchant_account']
      @environment = environment || 'live'
    end

    # This method will return nil by default. We can't do anything without creating an order.
    #
    # Expected params: any
    # Returns: nil
    def preview(*)
      nil
    end

    # Used for fetching subscription and verifying
    # if the subscription is valid, but that is not
    # possible with Adyen. Instead, payment is marked
    # as successful. Make sure you check payment
    # response before calling this method.
    #
    # Expected params: payment object with payment_token
    # Returns: Payment Result object
    def after_charge(payment:)
      PaymentResult.success(
        AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
        payment_token: payment[:payment_token],
        amount_cents: payment[:amount_cents],
        amount_currency: payment[:amount_currency].to_s
      )
    end

    # Used for cancelling subscription
    # If the cancellation is successful, the method will return a success struct with success = true
    # Else the method will return an error struct, with success = false
    #
    # Expected params: payment object with payment_token
    # Returns: Payment Result object
    def cancel_subscription(payment:)
      response = Api.cancel_recurring_subscription(credentials, payment[:payment_token])

      if response.code == 200 && VALID_SUBSCRIPTION_CANCEL_STATUSES.include?(response.to_s)
        PaymentResult.success(
          AccesstypeAdyen::PAYMENT_TYPE_RECURRING,
          message: 'Subscription cancelled successfully',
          status: response['status']
        )
      else
        error_response(response['errorCode'], response['message'], response['status'], payment[:payment_token])
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
