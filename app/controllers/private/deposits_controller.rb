module Private
  class DepositsController < BaseController
    before_action :auth_verified!

    def gen_address
      return head 404 unless currency.coin?

      current_user.get_account(currency).tap do |account|
        next unless account.payment_address.address.blank?
        account.payment_address.enqueue_address_generation
      end
      head 204
    end

    def destroy
      record = current_user.deposits.find(params[:id]).lock!
      if record.cancel!
        head 204
      else
        head 422
      end
    end

  private

    def currency
      @currency ||= Currency.find_by_code!(params[:currency])
    end
  end
end
