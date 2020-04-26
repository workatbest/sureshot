require_relative 'common_utils'
require 'csv'
require 'fileutils'
require 'descriptive_statistics'
require 'date'

class Options
  def date_to_s
    Date.today.to_s
  end

  def check_percent(num,sma,sma_200,close)
    per = close * (num/100)
    res = ''
    if sma.round.between?((close - per).round, (close + per).round)
      res = '*'
    elsif sma_200.round.between?((close - per).round, (close + per).round)
      res = '*'
    end
    res
  end
  def sma_ema
    threads = []
    CommonUtils.fno_list.each_line do |sym|
      sym.delete!("\n")
      old_sym = sym.strip
      sym = 'NSE:' + old_sym
      p "#{old_sym}"
      sma_data = CommonUtils.indicator_data(sym, 'SMA', 50)&.sma
      sma_200_data = CommonUtils.indicator_data(sym, 'SMA', 200)&.sma
      daily_data = CommonUtils.get_timeseries(sym, 'compact')&.close 
      if sma_data && sma_200_data && daily_data
        CSV.open("indicators/options.csv", 'a') do |csv|
          sma = sma_data[0][1].to_f
          sma_200 = sma_200_data[0][1].to_f
          close = daily_data[0][1].to_f
          res = check_percent(15.0,sma,sma_200,close)
          res << check_percent(10.0,sma,sma_200,close) if res != ''
          res << check_percent(5.0,sma,sma_200,close) if res != ''
          csv << [old_sym, sma, sma_200, close,res] if res != ''
        end
      end
    end
    threads.each do |t|
      t.join
    end
  end
end

indicators = Options.new
indicators.sma_ema
