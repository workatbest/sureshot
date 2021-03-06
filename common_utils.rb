require 'alphavantagerb'
require 'csv'
require 'fileutils'
require 'cgi'

SECRET_KEY='1OBOFRNE6KND478D'

class CommonUtils
  def self.get_timeseries(sym, output = 'full')
    for i in 0...5
      begin
        timeseries = Alphavantage::Timeseries.new symbol: CGI.escape(sym), key: SECRET_KEY, outputsize: output
        #timeseries = Alphavantage::Timeseries.new symbol: sym, key: SECRET_KEY
        p timeseries
        break
      rescue Alphavantage::Error => e 
        p e 
        p e.stacktrace
        sleep(30)
      end
    end
    timeseries
  end

  def self.indicator_data(sym, indicator, time_period)
    for i in 0...5
      begin
        data = Alphavantage::Indicator.new  function: indicator, symbol: CGI.escape(sym), key: SECRET_KEY, time_period: time_period
        p data
        break
      rescue Alphavantage::Error => e
        p e 
        p e.stacktrace
        sleep(30)
      end
    end
    data
  end

  def self.nse_list
    text=File.open('nse_fut_list.txt').read
    text.gsub!(/\r\n?/, "\n")
  end

  def self.indicators_list
    File.open('indicators_list.txt').read
  end

  def self.fno_list
    File.open('FNO.txt').read
  end
end
