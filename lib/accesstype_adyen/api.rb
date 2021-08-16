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

      # Used for charging the subscription payment.
      def charge_recurring_subscription(credentials, payload, subscription_plan, subscriber)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).charge_recurring_subscription(
          payload[:payment_token],
          payload[:amount_cents],
          payload[:amount_currency].to_s,
          subscription_plan[:id],
          subscriber[:id],
          credentials[:merchant_account]
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

      def webhook_signature_valid?(signature, body, secret)
        signature == OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, body)
      end
    end
  end
end
