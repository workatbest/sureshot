#!/usr/bin/env ruby

require_relative 'common_utils'
require 'csv'
require 'fileutils'
require 'descriptive_statistics'
require 'date'
require 'pry'

class VolatilityTrends

  class MonthDates
    attr_accessor :start_date, :end_date 
  end

  DAYS_TO_TRACK=250

  def calculate_daily_returns(timeseries, old_sym)
    dr_trends=[]
    # get data for only max last 30 days 
    max = timeseries.high.length < DAYS_TO_TRACK ? (timeseries.high.length - 1) : DAYS_TO_TRACK
    CSV.open("volatile_data/#{old_sym}.csv", 'wb') do |csv|
      csv << ['Date', 'Close', 'DailyReturn']
      for count in 0...max
        prev_day_close = timeseries.close[count+1][1].to_f == 0.0 ? timeseries.close[count+2][1].to_f : timeseries.close[count+1][1].to_f
        # Calculate the trend by comparing difference with closing price  
        dr = Math.log(timeseries.close[count][1].to_f/timeseries.close[count+1][1].to_f) * 100.0
        next if dr.infinite? or dr.nan?
        csv << [timeseries.close[count][0], timeseries.close[count][1].to_f, dr]
        dr_trends << dr
      end
    end
    positive_data = dr_trends.select { |item| item > 0.0 }
    return dr_trends.standard_deviation, positive_data.length, (dr_trends.length - positive_data.length)
  end

  def calculate_month_dates
    start_date = Date.today - DAYS_TO_TRACK
    binding.pry()
    while(start_date < Date.today)
      binding.pry()
      last_day = Date.civil(start_date.year, start_date.month, -1)
      last_friday = find_date(last_day, 5)
      prev_month = start_date.month == 1 ? 12 : start_date.month - 1
      prev_year = prev_month == 12 ? start_date.year - 1 : start_date.year
      last_thurday = find_date(Date.civil(prev_year, prev_month, -1), 4)
      binding.pry()
      p "#{last_friday.strftime('%Y-%m-%d')}  ---- #{last_thurday.strftime('%Y-%m-%d')}"
      start_date = last_thurday
    end
  end

  def find_date(day, wday)
    until day.wday == wday
      day -= 1
    end
    day
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
        sorted_list[old_sym] = calculate_daily_returns(timeseries, old_sym)
      else
        p "Failed to retrieve data"
      end
    end
    sorted_list = sorted_list.sort_by { |name, value| value[0] }
    p sorted_list.to_h.keys
    File.open("volatile_data/summary.txt", "w+") do |f|
      f.puts(sorted_list.to_h.keys)
    end
    File.open("volatile_data/summary.json","w") do |f|
      f.write(sorted_list.to_json)
    end
  end
end

vt = VolatilityTrends.new
vt.calculate_month_dates
#vt.volatility

