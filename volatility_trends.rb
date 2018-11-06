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

  def calculate_monthly_data(old_sym, timeseries)
    monthly_data = []
    start_date = Date.today - DAYS_TO_TRACK
    while(start_date < Date.today)
      last_day_prev_month = Date.civil(start_date.year, start_date.month, -1)
      data = find_data(find_date(last_day_prev_month, 4), timeseries)
      prev_month = start_date.month == 1 ? 12 : start_date.month - 1
      prev_year = prev_month == 12 ? start_date.year - 1 : start_date.year
      last_month_data = find_data(find_date(Date.civil(prev_year, prev_month, -1), 4).next, timeseries)
      #p data, last_month_data
      monthly_data << ["#{last_month_data['day']}##{data['day']}" , ((data['value'] - last_month_data['value'])/last_month_data['value']) * 100.0 ]
      next_month = start_date.month == 12 ? 1 : start_date.month + 1
      next_month_year = next_month == 1 ? start_date.year + 1 : start_date.year
      start_date = Date.civil(next_month_year, next_month,-1)
    end
    CSV.open("monthly_data/#{old_sym}.csv", 'wb') do |csv|
      csv << ['Date', 'Percent']
      monthly_data.each do |item|
        csv << item
      end
    end
  end

  def find_date(day, wday)
    until day.wday == wday
      day -= 1
    end
    day
  end

  def find_data(day, timeseries)
    data = {}
    while true do
      if timeseries[day.strftime('%Y-%m-%d')]
        data['day'] = day.strftime('%Y-%m-%d')
        data['value'] = timeseries[day.strftime('%Y-%m-%d')]['1. open'].to_f
        return data
      end
      day += 1
    end
  end

  def volatility
    FileUtils.rm_rf("indicator_data/.", secure: true)
    text=File.open('nse_fut_list.txt').read
    text.gsub!(/\r\n?/, "\n")

    sorted_list = {}
    indicator_list = {}
    monthly_data = {}
    text.each_line do |sym|
      sym.delete!("\n")
      old_sym = sym
      sym = 'NSE:' + sym
      timeseries = CommonUtils.get_timeseries(sym)
      if timeseries
        p timeseries.symbol
        sorted_list[old_sym] = calculate_daily_returns(timeseries, old_sym)
        calculate_monthly_data(old_sym, timeseries.hash['Time Series (Daily)'])
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
#vt.calculate_month_dates
vt.volatility

