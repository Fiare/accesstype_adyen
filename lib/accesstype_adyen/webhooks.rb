# frozen_string_literal: true

module AccesstypeAdyen
  # Used for handling different webhooks of adyen.
  class Webhooks
    attr_accessor :api_key, :hmac_key, :merchant_account, :environment, :payload

    def initialize(credentials:, environment:)
      @api_key = credentials[:api_key]
      @hmac_key = credentials[:hmac_key]
      @merchant_account = credentials[:merchant_account]
      @environment = environment || 'live'
    end

    # Mandatory
    # to authorize webhook received before processing it
    # Should return a boolean
    def webhook_request_authorized?(request:)
      body = JSON.parse(request.raw_post)

      # Return false if hmac key is missing, or message is completely
      # missing notification items or has zero notification items.

      return true if credentials.dig(:hmac_key).nil?
      
      if body['notificationItems'].nil? ||
        (!body['notificationItems'].nil? && body['notificationItems'].count.zero?)
        return false
      end

      body['notificationItems'].each do |item|
        unless HmacValidator.new.valid_notification_hmac?(
          item['NotificationRequestItem'],
          credentials[:hmac_key]
        )
          # One notification message can contain multiple items.
          # If any of the NotificationRequestItem hmac check fails,
          # return immediately false. Note that this then ignores all
          # items, even if there were valid items in that particular
          # message.
          return false
        end
      end

      true
    end

    # Mandatory
    # to identify which all webhook events are to be processed and the kind of processing required
    # Should return a map where values can be one of the supported types i.e ['one_time_subscription_charged',
    # 'recurring_subscription_charged', 'recurring_subscription_cancelled']
    def webhook_event_type_mapping
      {
        'AUTHORISATION' => 'one_time_subscription_charged',
        'REFUND'=> 'subscription_refund_created'
        # 'subscription.charged' => 'recurring_subscription_charged',
        # 'subscription.halted' => 'recurring_subscription_cancelled',
        # 'subscription.cancelled' => 'recurring_subscription_cancelled'
      }
    end

    # Mandatory
    # to identify all the required fields for processing
    # Should return a map with at least the mandatory keys as mentioned below
    def webhook_event_details(payload:)
      notification_item = payload.dig(:notificationItems, 0) || payload.dig(:payload, :notificationItems, 0)

      {
        attempt_token: notification_item.dig(:NotificationRequestItem, :merchantReference) || notification_item.dig(:NotificationRequestItem, :additionalData, 'metadata.attemptToken'),
        amount_currency: notification_item.dig(:NotificationRequestItem, :amount, :currency),
        amount_cents: notification_item.dig(:NotificationRequestItem, :amount, :value),
        status: notification_item.dig(:NotificationRequestItem, :success) == 'true' ? 'Success' : 'Failure',
        external_payment_id: notification_item.dig(:NotificationRequestItem, :pspReference),
        email: notification_item.dig(:NotificationRequestItem, :additionalData, :shopperEmail), # optional
        contact: nil, # optional
        event: notification_item.dig(:NotificationRequestItem, :eventCode),
        external_subscription_id: notification_item.dig(:NotificationRequestItem, :additionalData, :"recurring.recurringDetailReference"),
        payment_gateway_fee_cents: 0,
        payment_gateway_fee_currency: notification_item.dig(:NotificationRequestItem, :amount, :currency),
        external_refund_id: notification_item.dig(:NotificationRequestItem, :pspReference),
        external_original_reference_id: notification_item.dig(:NotificationRequestItem, :originalReference)
      }



    end

    # Optional
    # to be called while processing 'recurring_subscription_charged' type of events.
    # Its called just before exit in case there is no subscription to renew
    # return value does not matter
    # def before_exit_on_subscription_absence(payload:)
    #   @payload = payload
    #   begin
    #     subscription_id = payment_details[:external_subscription_id]
    #
    #     if subscription_id.blank?
    #       return PaymentResult.error(
    #         AccesstypeAdyen::PAYMENT_GATEWAY,
    #         payment_type: 'adyen_recurring',
    #         message: 'Subscription id not found'
    #       )
    #     end
    #
    #     cancel_result = Api.cancel_recurring_subscription(credentials, subscription_id)
    #
    #     external_payment_id = payment_details[:external_payment_id]
    #     payload = {
    #       'amount' => payment_details[:amount_cents].to_i,
    #       'notes' => { 'reason' => 'Subscription not present in acccesstype' }
    #     }
    #
    #     Api.refund_payment(credentials, external_payment_id, payload)
    #   rescue StandardError
    #     PaymentResult.error(
    #       AccesstypeAdyen::PAYMENT_GATEWAY,
    #       payment_type: 'adyen_recurring',
    #       message: 'Error occurred in before_exit_on_subscription_absence method'
    #     )
    #   end
    # end

    # Mandatory
    # to get the renewal details required while processing 'recurring_subscription_charged' type of events.
    # it should return payment result object with end_timestamp attribute which is received from the payment gateway.
    # def renewal(payload:)
    #   @payload = payload
    #   # call Razorpay APIs to get the details which are not available in the payload
    #   subscription = Api.get_subscription(credentials, payment_details[:external_subscription_id])
    #   end_timestamp = Time.zone.at(subscription['current_end'])&.to_datetime
    #
    #   if subscription['status'] == 'active' && end_timestamp&.future?
    #     payment = Api.get_payment(credentials, payment_details[:external_payment_id])
    #
    #     PaymentResult.success(
    #       AccesstypeAdyen::PAYMENT_GATEWAY,
    #       payment_type: 'adyen_recurring',
    #       external_subscription_id: subscription['id'],
    #       external_payment_id: payment['id'],
    #       amount_cents: payment[:amount],
    #       amount_currency: payment[:currency].to_s,
    #       end_timestamp: end_timestamp,
    #       international: payment['international'],
    #       payment_token: payment['id'],
    #       payment_gateway_fee: payment['fee'])
    #   else
    #     PaymentResult.error(
    #       AccesstypeAdyen::PAYMENT_GATEWAY,
    #       payment_type: 'adyen_recurring',
    #       message: "Subscription is not active for #{subscription['id']} or end date is not in future",
    #       code: subscription['error']['code'])
    #   end
    # end

    private

    def credentials
      { api_key: api_key, hmac_key: hmac_key, merchant_account: merchant_account, environment: environment }
    end
  end
end
