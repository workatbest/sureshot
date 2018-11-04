require 'alphavantagerb'
require 'csv'
require 'fileutils'

SECRET_KEY='1OBOFRNE6KND478D'

class CommonUtils
  def self.get_timeseries(sym)
    for i in 0...5
      begin
        timeseries = Alphavantage::Timeseries.new symbol: sym, key: SECRET_KEY, outputsize: 'full'
        #timeseries = Alphavantage::Timeseries.new symbol: sym, key: SECRET_KEY
        break
      rescue Alphavantage::Error
        sleep(25)
        p 'retrying'
      end
    end
    timeseries
  end
end
