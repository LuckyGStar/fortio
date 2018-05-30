class Order < ActiveRecord::Base
  extend Enumerize

  enumerize :bid, in: Currency.hash_codes
  enumerize :ask, in: Currency.hash_codes
  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true

  ORD_TYPES = %w(market limit)
  enumerize :ord_type, in: ORD_TYPES, scope: true

  SOURCES = %w(Web APIv2 debug)
  enumerize :source, in: SOURCES, scope: true

  after_commit :trigger
  before_validation :fix_number_precision

  validates_presence_of :ord_type, :volume, :origin_volume, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false,
    if: "ord_type == 'limit'"
  validate :market_order_validations, if: "ord_type == 'market'"

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  ATTRIBUTES = %w(id at market kind price state state_text volume origin_volume)

  belongs_to :member
  attr_accessor :total

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :position, -> { group("price").pluck(:price, 'sum(volume)') }

  def fee
    config[self.kind.to_sym]["fee"]
  end

  def config
    @config ||= Market.find(self.currency)
  end

  def trigger
    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end
    member.trigger('order', json)
  end

  def strike(trade)
    strike_price = trade.price
    strike_volume = trade.volume

    self.volume -= strike_volume
    real_sub, add = self.class.strike_sum(strike_volume, strike_price)
    real_fee = add * fee
    real_add = add - real_fee

    hold_account.unlock_and_sub_funds \
      real_sub, locked: sum(strike_volume), 
      reason: Account::STRIKE_SUB, ref: trade

    expect_account.plus_funds \
      real_add, fee: real_fee,
      reason: Account::STRIKE_ADD, ref: trade

    self.volume.zero? and self.state = Order::DONE
    self.save!
  end

  def kind
    type.underscore[-3, 3]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
  end

  def at
    created_at.to_i
  end

  def market
    currency
  end

  def avg_price
    if trades.empty?
      ::Trade::ZERO
    else
      sum = trades.map {|t| t.price*t.volume }.sum
      vol = trades.map(&:volume).sum
      sum / vol
    end
  end

  def to_matching_attributes
    { id: id,
      market: market,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      timestamp: created_at.to_i }
  end

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end

  private

  def fix_number_precision
    self.price = price.to_d.round(config.bid["fixed"], 2) if price
    self.volume = volume.to_d.round(config.ask["fixed"], 2) if volume
  end

end
