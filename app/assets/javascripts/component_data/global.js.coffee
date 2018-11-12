window.GlobalData = flight.component ->

  @refreshDocumentTitle = (event, data) ->
    symbol = gon.currencies[gon.market.bid.currency].symbol
    price  = data.last
    market = [gon.market.ask.currency, gon.market.bid.currency].join("/").toUpperCase()
    brand  = "Peatio Exchange"

    document.title = "#{symbol}#{price} #{market} - #{brand}"

  @refreshDepth = (data) ->
    [bids_sum, asks_sum] = [0, 0]
    asks = _.map data.asks, ([price, volume]) ->
      [parseFloat(price), asks_sum += parseFloat(volume)]
    bids = _.map data.bids, ([price, volume]) ->
      [parseFloat(price), bids_sum += parseFloat(volume)]

    la = _.last(asks)
    lb = _.last(bids)
    if la && lb
      mid = (_.first(bids)[0] + _.first(asks)[0]) / 2
      offset = Math.min.apply(Math, [mid*0.1, mid-lb[0], la[0]-mid])
    else if !la? && lb
      mid = _.first(bids)[0]
      offset = Math.min.apply(Math, [mid*0.1, mid-lb[0]])
    else if la && !lb?
      mid = _.first(asks)[0]
      offset = Math.min.apply(Math, [mid*0.1, la[0]-mid])

    @trigger 'market::depth::response', 
      asks: asks, bids: bids, high: mid + offset, low: mid - offset 

  @refreshTicker = (data) ->
    unless @.last_tickers
      for market, ticker of data
        data[market]['buy_trend'] = data[market]['sell_trend'] = data[market]['last_trend'] = true
      @.last_tickers = data

    tickers = for market, ticker of data
      buy = parseFloat(ticker.buy)
      sell = parseFloat(ticker.sell)
      last = parseFloat(ticker.last)
      last_buy = parseFloat(@.last_tickers[market].buy)
      last_sell = parseFloat(@.last_tickers[market].sell)
      last_last = parseFloat(@.last_tickers[market].last)

      if buy != last_buy
        data[market]['buy_trend'] = ticker['buy_trend'] = (buy > last_buy)
      else
        ticker['buy_trend'] = @.last_tickers[market]['buy_trend']

      if sell != last_sell
        data[market]['sell_trend'] = ticker['sell_trend'] = (sell > last_sell)
      else
        ticker['sell_trend'] = @.last_tickers[market]['sell_trend']

      if last != last_last
        data[market]['last_trend'] = ticker['last_trend'] = (last > last_last)
      else
        ticker['last_trend'] = @.last_tickers[market]['last_trend']

      if market == gon.market.id
        @trigger 'market::ticker', ticker

      market: market, data: ticker

    @trigger 'market::tickers', {tickers: tickers}
    @.last_tickers = data

  @after 'initialize', ->
    @on document, 'market::ticker', @refreshDocumentTitle

    global_channel = @attr.pusher.subscribe("market-global")
    market_channel = @attr.pusher.subscribe("market-#{gon.market.id}-global")

    global_channel.bind 'tickers', (data) =>
      @refreshTicker(data)

    market_channel.bind 'update', (data) =>
      gon.asks = data.asks
      gon.bids = data.bids
      @trigger 'market::order_book::update', asks: data.asks, bids: data.bids
      @refreshDepth asks: data.asks, bids: data.bids 

    market_channel.bind 'trades', (data) =>
      @trigger 'market::trades', {trades: data.trades}

    # Initializing at bootstrap
    if gon.ticker
      @trigger 'market::ticker', gon.ticker

    if gon.tickers
      @refreshTicker(gon.tickers)

    if gon.asks and gon.bids
      @trigger 'market::order_book::initialize', asks: gon.asks, bids: gon.bids
      @refreshDepth asks: gon.asks, bids: gon.bids 

    if gon.trades
      @trigger 'market::trades', trades: gon.trades.reverse()
