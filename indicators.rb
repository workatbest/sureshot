require_relative 'common_utils'
require 'csv'
require 'fileutils'
require 'descriptive_statistics'
require 'date'

class Indicators

  def calculate_sma_ema(old_sym, csv, sma_data, sma_200_data, ema_data, daily_data)
    # Line crossed 
    # If sma50 and ema line crossed
    prev_day_val = ema_data[1][1].to_f - sma_data[1][1].to_f
    today_val = ema_data[0][1].to_f - sma_data[0][1].to_f
    if (prev_day_val * today_val) < 0
      if daily_data[0][1] < sma_data[0][1]
        p "SMA50-EMA Line Crossed downward #{old_sym}"  
        csv << [old_sym, 'SMA50-EMA Line Crossed Downward', date_to_s]
      else
        p "SMA50-EMA Line Crossed upward #{old_sym}"  
        csv << [old_sym, 'SMA50-EMA Line Crossed Upward', date_to_s]
      end
    end
    # If sma200 and ema line crossed
    prev_day_val = ema_data[1][1].to_f - sma_200_data[1][1].to_f
    today_val = ema_data[0][1].to_f - sma_200_data[0][1].to_f
    if (prev_day_val * today_val) < 0
      if daily_data[0][1] < sma_200_data[0][1]
        p "SMA200-EMA Line Crossed downward #{old_sym}"  
        csv << [old_sym, 'SMA200-EMA Line Crossed Downward', date_to_s]
      else
        p "SMA200-EMA Line Crossed upward #{old_sym}"  
        csv << [old_sym, 'SMA200-EMA Line Crossed Upward', date_to_s]
      end
    end
  end

  def date_to_s
    Date.today.to_s
  end

  def sma_ema
    threads = []
    CommonUtils.indicators_list.each_line do |sym|
      sym.delete!("\n")
      old_sym = sym
      sym = 'NSE:' + old_sym
      p "#{old_sym}"
      sma_data = CommonUtils.indicator_data(sym, 'SMA', 50)&.sma
      sma_200_data = CommonUtils.indicator_data(sym, 'SMA', 200)&.sma
      ema_data = CommonUtils.indicator_data(sym, 'EMA', 13)&.ema
      daily_data = CommonUtils.get_timeseries(sym, 'compact')&.close 
      if sma_data && sma_200_data && ema_data && daily_data
        CSV.open("indicators/sma_ema.csv", 'a') do |csv|
          calculate_sma_ema(old_sym, csv, sma_data, sma_200_data, ema_data, daily_data)
        end
      end
    end
    threads.each do |t|
      t.join
    end
  end
end

indicators = Indicators.new
indicators.sma_ema
