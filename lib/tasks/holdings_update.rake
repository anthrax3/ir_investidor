require 'csv'

namespace :holdings do
  desc '[Temporary Task] Update prices of all holdings'
  task :update => :environment do
    stocks = []
    Holding.select(:asset, :asset_name).group(:asset, :asset_name).each do |h|
      if h.asset == Transaction::ASSET['stock']
        stocks << h.asset_name.upcase.strip + '.SA'
      end
    end

    args = {
      's' => stocks.join(' '),
      'f' => 'sl1'
    }
    url = "?s=HYPE3.SA+BVMF3.SA&f=sl1"
    agent = Mechanize.new
    agent.get('http://finance.yahoo.com/d/quotes.csv', args)
    CSV.parse(agent.page.body).each do |row|
      symbol, price = row
      symbol = symbol.gsub(/\.SA\Z/, '')
      Holding.where(asset: Transaction::ASSET['stock'])
             .where(asset_name: symbol)
             .update_all(current_price: BigDecimal.new(price))
    end
    agent.shutdown
  end
end
