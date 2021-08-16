# frozen_string_literal: true

module AccesstypeAdyen
  # Used for calling adyen APIs
  class Client
    attr_reader :config, :credentials

    # Define routes which will be used in this class
    ROUTES = [
      { name: 'capture_payment', path: '/v67/payments/:payment_id/captures', api: :checkout },
      { name: 'refund_payment', path: '/v67/payments/:payment_id/refunds', api: :checkout },
      { name: 'charge_recurring_subscription', path: '/v67/payments', api: :checkout },
      { name: 'cancel_recurring_subscription', path: '/Recurring/v49/disable', api: :pal },
      { name: 'validate_credentials', path: '/v67/paymentMethods', api: :checkout }
    ].freeze

    # The frequency with which a shopper should be charged.
    # Possible values: daily, weekly, biWeekly, monthly,
    #                  quarterly, halfYearly, yearly.
    #
    # See more: https://docs.adyen.com/api-explorer/#/CheckoutService/v67/post/payments__reqParam_mandate-frequency
    FREQUENCY = {
      'days' => 'daily',
      'weeks' => 'weekly',
      'months' => 'monthly',
      'years' => 'yearly'
    }.freeze

    def initialize(config, credentials)
      @config = config
      @credentials = credentials
    end

    # Used for capturing payment from Adyen PG.
    def capture_payment(payment_id, currency, amount, merchant_account)
      fetch_route = find_route(__method__.to_s)
      requested_path = fetch_route[:path].gsub(':payment_id', payment_id)

      client.post(
        requested_path,
        fetch_route[:api],
        {
          amount: { currency: currency, value: amount },
          merchant_account: merchant_account
        }
      )
    end

    def refund_payment(payment_id, refund_currency, refund_amount, merchant_account)
      fetch_route = find_route(__method__.to_s)
      requested_path = fetch_route[:path].gsub(':payment_id', payment_id)

      client.post(
        requested_path,
        fetch_route[:api],
        {
          'amount' => { 'currency' => refund_currency, 'amount' => refund_amount },
          'merchantAccount' => merchant_account
        }
      )
    end

    def charge_recurring_subscription(payment_token, payment_amount, payment_currency, subscription_id, subscriber_id, merchant_account)
      fetch_route = find_route(__method__.to_s)
      requested_path = fetch_route[:path]

      client.post(
        requested_path,
        fetch_route[:api],
        {
          'amount' => { 'currency' => payment_currency, 'amount' => payment_amount },
          'paymentMethod' => { 'type' => 'scheme', 'storedPaymentMethodId' => payment_token },
          'reference' => subscription_id,
          'shopperInteraction' => 'ContAuth',
          'recurringProcessingModel' => 'Subscription',
          'shopperReference' => subscriber_id,
          'merchantAccount' => merchant_account
        }
      )
    end

    # If recurringDetailReference is not provided,
    # the whole recurring contract of the shopperReference
    # will be disabled, which includes all recurring details.
    #
    # See more: https://docs.adyen.com/api-explorer/#/Recurring/latest/post/disable__section_reqParams
    def cancel_recurring_subscription(subscriber_id, merchant_account)
      fetch_route = find_route(__method__.to_s)
      requested_path = fetch_route[:path]

      client.post(
        requested_path,
        fetch_route[:api],
        {
          'contract' => 'RECURRING',
          'shopperReference' => subscriber_id,
          'merchantAccount' => merchant_account
        }
      )
    end

    # This will just use paymentMethods API endpoint
    # to test that will will return 200 with provided
    # credentials and merchantAccount
    def validate_credentials(merchant_account)
      fetch_route = find_route(__method__.to_s)
      requested_path = fetch_route[:path]

      client.post(
        requested_path,
        fetch_route[:api],
        {
          'merchantAccount' => merchant_account
        }
      )
    end

    private

    def client
      @client ||= ApiClient.new(config, credentials)
    end

    def find_route(method_name)
      ROUTES.find { |route| route[:name] == method_name }
    end
  end
end
