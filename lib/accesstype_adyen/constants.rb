# frozen_string_literal: true

module AccesstypeAdyen
  # Define constants which can be used in gem.
  CONFIG = {
    sandbox: {
      checkout: { root_url: 'https://checkout-test.adyen.com' },
      pal: { root_url: 'https://pal-test.adyen.com/pal/servlet' }
    },
    live: {
      checkout: { root_url: 'https://checkout.adyen.com' },
      pal: { root_url: 'https://pal.adyen.com/pal/servlet' }
    }
  }.freeze

  # https://docs.adyen.com/online-payments/payment-result-codes

  # All the valid payment result statuses
  # See more: https://docs.adyen.com/online-payments/payment-result-codes
  VALID_STATUSES = [
    'AuthenticationFinished', # The payment has been successfully authenticated with 3D Secure.
    'AuthenticationNotRequired', # The transaction does not require 3D Secure authentication.
    'Authorised', # The payment was successfully authorised.
    'ChallengeShopper', # The issuer requires further shopper interaction before the payment can be authenticated. Returned for 3D Secure 2 transactions.
    'IdentifyShopper', # The issuer requires the shopper's device fingerprint before the payment can be authenticated. Returned for 3D Secure 2 transactions.
    'PresentToShopper', # Present the voucher or the QR code to the shopper.
    'Received', # This is part of the standard payment flow for methods such as SEPA Direct Debit, where it can take some time before the final status of the payment is known.
    'RedirectShopper', # The shopper needs to be redirected to an external web page or app to complete the payment.
  ].freeze

  # Other possible result code statuses:
  # 'Cancelled', The payment was cancelled (by either the shopper or your own system) before processing was completed.
  # 'Error', There was an error when the payment was being processed.
  # 'Pending' It's not possible to obtain the final status of the payment at this time.
  # 'Refused' The payment was refused.

  # See more: https://docs.adyen.com/online-payments/classic-integrations/api-integration-ecommerce/recurring-payments/disable-stored-details#response
  VALID_SUBSCRIPTION_CANCEL_STATUSES = [
    '[detail-successfully-disabled]', # When a single detail is disabled.
    '[all-details-successfully-disabled]' # When all the details are disabled.
  ].freeze

  PAYMENT_GATEWAY = 'adyen'
  PAYMENT_TYPE_RECURRING = 'adyen_recurring'
end
