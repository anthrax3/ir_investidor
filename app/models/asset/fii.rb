# References:
# http://www.bmfbovespa.com.br/pt_br/servicos/tarifas/listados-a-vista-e-derivativos/renda-variavel/tarifas-de-acoes-e-fundos-de-investimento/a-vista/
# https://www.easynvest.com.br/tributacaorendavariavel
class Asset::Fii < Asset::Base
  def self.costs(transaction)
    items = {}
    items['Corretagem'] = BigDecimal.new('1.99')
    items['Corretagem - ISS (5%)'] = (BigDecimal.new('1.99') * 0.05).floor(2)
    items['Emolumentos/Negociação (0,005%)'] = (transaction.value * 0.000050).floor(2)
    items['Liquidação (0,0275%)'] = (transaction.value * 0.000275).floor(2)
    items
  end

  def self.irrf(transaction)
    if transaction.operation == Transaction::OPERATION['sell']
      (transaction.value * 0.00005).floor(2)
    else
      0
    end
  end

  def self.tax_aliquot(transaction=nil)
    0.20
  end

  def self.name(transaction)
    transaction.ticker
  end

  def self.identifier(transaction)
    transaction.ticker
  end

  def self.process(transaction)
    qtd = transaction.quantity_with_sign

    holding = Holding.for(transaction)
    if holding.blank?
      # create a new holding
      holding = Holding.new
      holding.user_id           = transaction.user_id
      holding.asset             = transaction.asset
      holding.asset_identifier  = transaction.asset_identifier
      holding.asset_name        = transaction.asset_name
      holding.initial_price     = transaction.price_considering_costs
      holding.current_price     = holding.initial_price
      holding.last_operation_at = transaction.operation_at
      holding.user_brokers[transaction.user_broker_id] = qtd
      holding.books[transaction.book_id]               = qtd
      holding.quantity                                 = qtd
      holding.save!

    elsif qtd * holding.quantity < 0
      # the transaction decreases the holding quantity

      # Calculate taxes for the transaction
      Asset::Fii.calculate_taxes(transaction)

      if qtd.abs > holding.quantity.abs
        # if changing vision about the asset (e.g. from short to long), the
        # initial price is recalculated
        holding.initial_price = transaction.price_considering_costs
        holding.current_price = holding.initial_price
        holding.user_brokers.clear # reset
        holding.books.clear # reset
      end

      holding.last_operation_at = transaction.operation_at
      holding.quantity += qtd

      if holding.quantity == 0
        holding.destroy
      else
        holding.user_brokers[transaction.user_broker_id] ||= 0
        holding.user_brokers[transaction.user_broker_id] += qtd
        holding.books[transaction.book_id]               ||= 0
        holding.books[transaction.book_id]               += qtd
        holding.save!
      end

      holding.quantity == 0 ? holding.destroy : holding.save!

    else
      # the transaction increases the holding quantity
      price = ((qtd * transaction.price_considering_costs) +
               (holding.quantity * holding.initial_price)) /
              (qtd + holding.quantity)

      holding.initial_price     = price
      holding.current_price     = holding.initial_price
      holding.last_operation_at = transaction.operation_at
      holding.quantity          += qtd
      holding.user_brokers[transaction.user_broker_id] ||= 0
      holding.user_brokers[transaction.user_broker_id] += qtd
      holding.books[transaction.book_id]               ||= 0
      holding.books[transaction.book_id]               += qtd
      holding.save!
    end
  end

  def self.calculate_taxes(transaction)
    net_earnings = transaction.net_earnings
    daytrade = transaction.daytrade?
    irrf = transaction.irrf
    aliquot = Asset::Fii.tax_aliquot(transaction)

    tax = transaction.user.tax_for(transaction.operation_at)
    if daytrade
      tax.net_earnings_day_trade += net_earnings
    else
      tax.net_earnings += net_earnings
    end
    tax_entry = tax.tax_entries.build
    tax_entry.asset = transaction.asset
    tax_entry.asset_name = transaction.asset_name
    tax_entry.daytrade = daytrade
    tax_entry.net_earning = net_earnings
    tax_entry.aliquot = aliquot
    tax.irrf += irrf
    tax_entry.irrf = irrf
    tax_entry.tax_value = aliquot * net_earnings if net_earnings > 0
    tax_entry.operation_at = transaction.operation_at
    tax.save!
  end
end
