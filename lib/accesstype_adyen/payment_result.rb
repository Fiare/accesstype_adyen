# frozen_string_literal: true

module AccesstypeAdyen
  # Define a common response structure which will be given to Accesstype.
  class PaymentResult
    attr_accessor :success, :code, :message, :payload, :payment_token, :amount_currency, :amount_cents, :status, :transaction_id, :payment_type, :international, :skip_invoice, :metadata, :external_payment_id, :authorize_uri, :payment_gateway_fee, :payment_gateway_fee_currency, :external_refund_id, :external_capture_id

    def self.error(payment_type, params = {})
      result = PaymentResult.new
      result.success = false
      result.code = params[:code]
      result.message = params[:message]
      result.payment_type = payment_type
      result.status = params[:status]
      result.payload = params[:payload]
      result.authorize_uri = params[:authorize_uri]
      result
    end

    def self.success(payment_type, params = {})
      result = PaymentResult.new
      result.payment_type = payment_type
      result.success = true
      result.message = params[:message]
      result.payload = params[:payload]
      result.payment_gateway_fee = params[:payment_gateway_fee]
      result.payment_token = params[:payment_token] || nil
      result.status = params[:status]
      result.amount_currency = params[:amount_currency]
      result.amount_cents = params[:amount_cents]
      result.international = params[:international]
      result.skip_invoice = params[:skip_invoice]
      result.metadata = params[:metadata]
      result.external_payment_id = params[:external_payment_id]
      result.external_capture_id = params[:external_capture_id]
      result.payment_gateway_fee_currency = params[:payment_gateway_fee_currency]
      result.external_refund_id = params[:external_refund_id]

      result
    end

    def failed?
      !success
    end

    def payment
      {
        payment_token: payment_token,
        amount_cents: amount_cents,
        amount_currency: amount_currency,
        payment_type: payment_type,
        international: international,
        skip_invoice: skip_invoice,
        metadata: metadata,
        external_payment_id: external_payment_id
      }
    end
  end
end
