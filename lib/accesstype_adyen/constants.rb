# frozen_string_literal: true

module AccesstypeAdyen
  # Define constants which can be used in gem.
  CONFIG = {
    sandbox: {
      checkout: { root_url: 'https://checkout-test.adyen.com' },
      pal: { root_url: 'https://pal-test.adyen.com/pal/servlet' }
    },
    live: {
      checkout: { root_url: 'https://checkout-test.adyen.com' },
      pal: { root_url: 'https://pal-test.adyen.com/pal/servlet' }
    }
  }.freeze

  # https://docs.adyen.com/online-payments/payment-result-codes

  # TODO: Please add all the valid statuses IMPORTANT 
  VALID_STATUSES = ['Authorised', 'RedirectShopper', 'IdentifyShopper'].freeze
  VALID_SUBSCRIPTION_CANCEL_STATUSES = ['[detail-successfully-disabled]', '[all-details-successfully-disabled]'].freeze

  PAYMENT_GATEWAY = 'adyen'
  PAYMENT_TYPE_RECURRING = 'adyen_recurring'
end
