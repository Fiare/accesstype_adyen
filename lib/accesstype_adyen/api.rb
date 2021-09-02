# frozen_string_literal: true

module AccesstypeAdyen
  # Contains all the methods which will be called by onetime and recurring payment.
  class Api
    class << self
      # Used for capturing payment from Adyen.
      def capture_payment(credentials, external_payment_id, payment_amount, payment_currency)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).capture_payment(
          external_payment_id,
          payment_currency,
          payment_amount,
          credentials[:merchant_account]
        )
      end

      # Used for refund the payment from Adyen.
      def refund_payment(credentials, payment_id, currency, amount)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).refund_payment(
          payment_id,
          currency,
          amount,
          credentials[:merchant_account]
        )
      end

      # Used for charging the onetime payment.
      def charge_onetime(credentials, payload)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).charge_onetime(
          payload[:subscription][:additional_data][:dropin_state_data][:paymentMethod],
          payload[:subscription][:payment][:amount_cents],
          payload[:subscription][:payment][:amount_currency].to_s,
          credentials[:merchant_account],
          payload[:attempt_token],
          payload[:subscription][:additional_data][:return_url],
          payload[:subscription][:additional_data][:dropin_state_data][:browserInfo] ? payload[:subscription][:additional_data][:dropin_state_data][:browserInfo].to_enum.to_h : nil,
          payload[:subscription][:additional_data][:origin]

        )
      end

      # Used for charging the subscription payment.
      #
      # Payload contains "attempt_token" that needs to be passed to
      # payment in its metadata, so in the notification webhook payment
      # can be identified by the attempt token value.
      # See more: https://docs.adyen.com/api-explorer/#/CheckoutService/v67/post/payments__reqParam_metadata
      def charge_recurring_subscription(credentials, payload, subscription_plan, subscriber)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).charge_recurring_subscription(
          payload[:subscription][:additional_data][:dropin_state_data][:paymentMethod],
          payload[:subscription][:payment][:amount_cents],
          payload[:subscription][:payment][:amount_currency].to_s,
          credentials[:merchant_account],
          payload[:attempt_token],
          payload[:subscription][:additional_data][:return_url],
          payload[:subscription][:additional_data][:dropin_state_data][:browserInfo] ? payload[:subscription][:additional_data][:dropin_state_data][:browserInfo].to_enum.to_h : nil,
          payload[:subscription][:additional_data][:origin],
          subscriber[:id]
        )
      end

      # Used for cancelling the subscription.
      def cancel_recurring_subscription(credentials, subscriber_id)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).cancel_recurring_subscription(
          subscriber_id,
          credentials[:merchant_account]
        )
      end

      # Used for testing that the credentials and merchantAccount are valid.
      def validate_credentials(credentials)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).validate_credentials(
          credentials[:merchant_account]
        )
      end

      # Used to send payment details to payment gateway after redirection was needed
      def payment_details(credentials, details, payment_data)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).payment_details(details, payment_data)
      end
    end
  end
end
