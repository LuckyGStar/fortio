module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def set_fee
      self.fee = "0.0001".to_d
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def audit!
      result = CoinRPC[currency].validateaddress(fund_uid)

      if result.nil? || (result[:isvalid] == false)
        Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
        reject!
      elsif (result[:ismine] == true) || PaymentAddress.find_by_address(fund_uid)
        reject!
      else
        super
      end
    rescue
      puts "Error on coin withdraw: #{$!}"
      puts $!.backtrace.join("\n")
    end

  end
end

