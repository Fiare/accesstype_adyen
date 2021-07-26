# frozen_string_literal: true

module AccesstypeAdyen
  # Contains all the methods which will be called by onetime and recurring payment.
  class Api
    class << self
      # Used for capturing payment from Adyen PG.
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

      # Used for refund the payment from Adyen
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

      def cancel_recurring_subscription(credentials, subscription_id)
        Client.new(
          AccesstypeAdyen::CONFIG[credentials[:environment].to_sym],
          credentials
        ).cancel_recurring_subscription(
          subscription_id,
          credentials[:merchant_account]
        )
      end
    end
  end
end
