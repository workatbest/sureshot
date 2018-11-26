require_relative 'common_utils'
require 'csv'
require 'fileutils'
require 'descriptive_statistics'
require 'date'

class Indicators

  def calculate_sma_ema(old_sym, csv, sma_data, sma_200_data, ema_data, daily_data)
    # Line crossed 
    prev_day_val = ema_data[1][1].to_f - sma_data[1][1].to_f
    today_val = ema_data[0][1].to_f - sma_data[0][1].to_f
    if (prev_day_val * today_val) < 0
      if sma_200_data[0][1] < ema_data[0][1] && sma_200_data[0][1] < sma_data[0][1]
        if daily_data[0][1] < sma_data[0][1]
          p "Line Crossed downward #{old_sym}"  
          csv << [old_sym, 'Line Crossed Downward']
        else
          p "Line Crossed upward #{old_sym}"  
          csv << [old_sym, 'Line Crossed Upward']
        end
      end
    end
    # EMA downwards
    # If it was above all 3 indicators prev day and went just below EMA today
    if daily_data[1][1] > sma_data[1][1] && daily_data[1][1] > sma_200_data[1][1] && daily_data[1][1] > ema_data[1][1]
      if daily_data[0][1] < ema_data[0][1] && daily_data[0][1] > sma_data[0][1] && daily_data[0][1] > sma_200_data[0][1]
        p "EMA downwards #{old_sym}"
        csv << [old_sym, 'EMA Downward']
      end
    end
    # EMA upwards
    # If it was below ema and above both sma prev day and then goes above ema 
    if daily_data[1][1] < ema_data[1][1] && daily_data[1][1] > sma_200_data[1][1] && daily_data[1][1] > sma_data[1][1]
      if daily_data[0][1] > ema_data[0][1]
        p "EMA upward #{old_sym}"
        csv << [old_sym, 'EMA Upward']
      end
    end
    p "Completed #{old_sym}"
  end

  def sma_ema
    threads = []
    CSV.open("indicators/sma_ema.csv", 'wb') do |csv|
      csv << ['Name', 'Trend']
      CommonUtils.nse_list.each_line do |sym|
        sym.delete!("\n")
        old_sym = sym
        sym = 'NSE:' + sym
        p "#{old_sym}"
        sma_data = CommonUtils.indicator_data(sym, 'SMA', 50)&.sma
        sma_200_data = CommonUtils.indicator_data(sym, 'SMA', 200)&.sma
        ema_data = CommonUtils.indicator_data(sym, 'EMA', 20)&.ema
        daily_data = CommonUtils.get_timeseries(sym, 'compact')&.close 
        if sma_data && sma_200_data && ema_data && daily_data
          #p "EMA:", ema_data[1], ema_data[0]
          #p "SMA:", sma_data[1], sma_data[0]
          #p "CLOSE:", daily_data[1], daily_data[0]
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
