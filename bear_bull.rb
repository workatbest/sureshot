#!/usr/bin/env ruby

require_relative 'common_utils'
require 'csv'
require 'fileutils'
require 'descriptive_statistics'
require 'date'

class BearBull

  class MonthDates
    attr_accessor :start_date, :end_date 
  end

  BEAR_BULL_COMAPRE=0.002
  DIFFERENCE_CANDLE=0.003
  CANDLES_COUNT=3

  def bear_bull_finder(timeseries, old_sym, csv)
    # check if the candle difference valid for 4 days
    found = true
    for count in 0...(CANDLES_COUNT+1)
      #p timeseries.close[count][1], timeseries.open[count][1]
      base = timeseries.close[count][1].to_f < timeseries.open[count][1].to_f ? timeseries.close[count][1].to_f : timeseries.open[count][1].to_f
      if ((timeseries.close[count][1].to_f - timeseries.open[count][1].to_f).abs/base) < DIFFERENCE_CANDLE
        found = false
        break
      end
    end
    if found
      # check if todays open is above prev days clpse by compare value 
      #p (timeseries.close[1][1].to_f * BEAR_BULL_COMAPRE)
      #p "Bear #{(timeseries.close[1][1].to_f - (timeseries.close[1][1].to_f * BEAR_BULL_COMAPRE))}"
      #p "Bull #{(timeseries.close[0][1].to_f - (timeseries.close[0][1].to_f * BEAR_BULL_COMAPRE))}"
      if (timeseries.close[1][1].to_f + (timeseries.close[1][1].to_f * BEAR_BULL_COMAPRE)) < timeseries.open[0][1].to_f && timeseries.open[1][1] < timeseries.close[0][1] && timeseries.close[1][1] < timeseries.open[0][1] && green_candle(timeseries.open[0][1], timeseries.close[0][1])
        # bull finder
        bull = true
        for count in 1...CANDLES_COUNT
          #p "bull---"
          #p " Prev open - #{timeseries.open[count+1][1]}  close #{timeseries.close[count+1][1]}"
          #p " today open - #{timeseries.open[count][1]}  close #{timeseries.close[count][1]}"
          #p (timeseries.open[count+1][1].to_f * BEAR_BULL_COMAPRE)
          #p (timeseries.open[count+1][1].to_f - (timeseries.open[count+1][1].to_f * BEAR_BULL_COMAPRE))
          if (timeseries.open[count+1][1].to_f - (timeseries.open[count+1][1].to_f * BEAR_BULL_COMAPRE)) < timeseries.open[count][1].to_f 
            if timeseries.close[count+1][1].to_f > timeseries.open[count][1].to_f && red_candle(timeseries.open[count][1], timeseries.close[count][1])
              bull = true
            else
              bull = false
            end
          else
            bull = false
          end
          break unless bull
        end
        if bull
          p "<---------------------Found bull--------------------->  #{old_sym}" 
          csv << [old_sym, 'BULL', timeseries.close[0][1], timeseries.close[1][1], date_to_s]  
        end
      elsif (timeseries.close[1][1].to_f - (timeseries.close[1][1].to_f * BEAR_BULL_COMAPRE)) > timeseries.open[0][1].to_f && timeseries.close[1][1] > timeseries.open[0][1] && timeseries.open[1][1] > timeseries.close[0][1] && red_candle(timeseries.open[0][1], timeseries.close[0][1])
        # bear finder
        bear = true
        for count in 1...CANDLES_COUNT
          #p "bear---"
          #p " Prev open - #{timeseries.open[count+1][1]}  close #{timeseries.close[count+1][1]}"
          #p " today open - #{timeseries.open[count][1]}  close #{timeseries.close[count][1]}"
          #p (timeseries.open[count+1][1].to_f * BEAR_BULL_COMAPRE)
          #p (timeseries.open[count+1][1].to_f + (timeseries.open[count+1][1].to_f * BEAR_BULL_COMAPRE))
          if (timeseries.open[count+1][1].to_f + (timeseries.open[count+1][1].to_f * BEAR_BULL_COMAPRE)) < timeseries.open[count][1].to_f 
            if timeseries.close[count+1][1].to_f < timeseries.close[count][1].to_f && green_candle(timeseries.open[count][1], timeseries.close[count][1])
              bear = true
            else
              bear = false
            end
          else
            bear = false
          end
          break unless bear
        end
        if bear 
          p "<---------------------Found bear--------------------->  #{old_sym}" 
          csv << [old_sym, 'BEAR', timeseries.close[0][1], timeseries.close[1][1], date_to_s]
        end
      end
    end
  end

  def red_candle(open, close)
    open > close
  end

  def green_candle(open, close)
    close > open 
  end

  def date_to_s
    Date.today.to_s
  end

  def run
    text=File.open('nse_500.txt').read
    text.gsub!(/\r\n?/, "\n")

    CSV.open("indicators/bear_bull_indicator.csv", 'wb') do |csv|
      csv << ['Name', 'Type', 'Buy Price', 'Stop Loss', 'Date']
      text.each_line do |sym|
        sym.delete!("\n")
        old_sym = sym
        sym = 'NSE:' + sym
        timeseries = CommonUtils.get_timeseries(sym)
        if timeseries
          p timeseries.symbol
          bear_bull_finder(timeseries,old_sym,csv)
        else
          p "Failed to retrieve data"
        end
      end
    end
  end
end

vt = BearBull.new
#vt.calculate_month_dates
vt.run
