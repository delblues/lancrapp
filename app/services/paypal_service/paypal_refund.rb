module PaypalService
  module PaypalRefund
    PaypalRefundModel = ::PaypalRefund
    PaypalPaymentModel = ::PaypalPayment

    module Entity
      module_function

      PaypalRefund = EntityUtils.define_builder(
        [:paypal_payment_id, :mandatory, :fixnum],
        [:payment_total, :mandatory, :money],
        [:payment_fee, :mandatory, :money])

      def from_model(paypal_refund)
        hash = HashUtils.compact(
          EntityUtils.model_to_hash(paypal_refund).merge({
              payment_total: MoneyUtil.to_money(paypal_refund.payment_total_cents, paypal_refund.currency),
              payment_fee: MoneyUtil.to_money(paypal_refund.fee_total_cents, paypal_refund.currency)
            }))

        PaypalRefund.call(hash)
      end

    end

    module Command
      module_function

      def create(refund)
        init_data = {
          paypal_payment_id: paypal_payment_id(refund[:payment_id]),
          currency: refund[:payment_total].currency.iso_code,
          payment_total_cents: refund[:payment_total].fractional,
          fee_total_cents: refund[:fee_total].fractional,
          refunding_id: refund[:refunding_id]
        }

        model = PaypalRefundModel.create!(init_data)
        Entity.from_model(model)
      end

      #private
      def paypal_payment_id(payment_id)
        PaypalPaymentModel.where(payment_id: payment_id).pluck(:id).first
      end
    end
  end
end
