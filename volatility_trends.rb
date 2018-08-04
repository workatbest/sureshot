require_relative 'common_utils'
require 'csv'
require 'fileutils'
require 'descriptive_statistics'

class VolatilityTrends

  DAYS_TO_TRACK=250

  def calculate_daily_returns(timeseries, old_sym)
    dr_trends=[]
    # get data for only max last 30 days 
    max = timeseries.high.length < DAYS_TO_TRACK ? (timeseries.high.length - 1) : DAYS_TO_TRACK
    CSV.open("volatile_data/#{old_sym}.csv", 'wb') do |csv|
      csv << ['Date', 'Close', 'DailyReturn']
      for count in 0...max
        next if timeseries.close[count][1].to_f == 0.0
        prev_day_close = timeseries.close[count+1][1].to_f == 0.0 ? timeseries.close[count+2][1].to_f : timeseries.close[count+1][1].to_f
        # Calculate the trend by comparing difference with closing price  
        dr = Math.log(timeseries.close[count][1].to_f/prev_day_close) * 100.0
        csv << [timeseries.close[count][0], timeseries.close[count][1].to_f, dr]
        dr_trends << dr
      end
    end
    dr_trends.standard_deviation
  end

  def volatility
    FileUtils.rm_rf("indicator_data/.", secure: true)
    text=File.open('nse_fut_list.txt').read
    text.gsub!(/\r\n?/, "\n")

    sorted_list = {}
    indicator_list = {}
    text.each_line do |sym|
      sym.delete!("\n")
      old_sym = sym
      sym = 'NSE:' + sym
      timeseries = CommonUtils.get_timeseries(sym)
      if timeseries
        p timeseries.symbol
        avg = calculate_daily_returns(timeseries, old_sym)
        p avg
        sorted_list[old_sym] = avg unless avg.nan?
      else
        p "Failed to retrieve data"
      end
    end
    sorted_list = sorted_list.sort_by { |name, value| value }
    p sorted_list.to_h.keys
    File.open("volatile_data/summary.json","w") do |f|
      f.write(sorted_list.to_json)
    end
  end
end

vt = VolatilityTrends.new
vt.volatility

