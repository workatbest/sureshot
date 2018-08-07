require 'alphavantagerb'
require 'csv'
require 'fileutils'

DAYS_TO_TRACK=90
PERCENT_THRESHOLD=8.0
SECRET_KEY='1OBOFRNE6KND478D'
INDICATOR_PERCENT=20
INDICATOR_DAYS=10

def get_timeseries(sym)
  for i in 0...5
    begin
      timeseries = Alphavantage::Timeseries.new symbol: sym, key: SECRET_KEY
      break
    rescue Alphavantage::Error
      sleep(21)
      p 'retrying'
    end
  end
  timeseries
end

def indicator(sym)
  for i in 0...5
    begin
      data = Alphavantage::Indicator.new function: 'SMA', symbol: sym, key: SECRET_KEY, interval: 'daily', time_period: '200', series_type: 'close'
      break
    rescue Alphavantage::Error
      sleep(21)
      p 'retrying'
    rescue NoMethodError
      return nil
    end
  end
  data.hash.to_a[1].to_a[1].to_a if data
end

def calculate_indicator_trends(indicatorseries, timeseries, old_sym)
  indicator_trends=[]
  difference_data=[] 
  for count in 0...INDICATOR_DAYS
    # Calculate the trend by comparing difference with closing price  
    difference = ((timeseries.close[count][1].to_f - indicatorseries[count][1]['SMA'].to_f)/timeseries.close[count][1].to_f) * 100
    difference_data << difference.abs
    indicator_trends << [indicatorseries[count][0], timeseries.close[count][1].to_f, indicatorseries[count][1]['SMA'].to_f, difference]
  end
  if difference_data.max < INDICATOR_PERCENT
    CSV.open("indicator_data/#{old_sym}.csv", 'wb') do |csv|
      csv << ['Date', 'Close', 'SMA', 'Change']
      indicator_trends.each do |data|
        csv << data
      end
    end
    return difference_data[0]
  end
end

def calculate_trends(timeseries, old_sym)
  high_trends=[]
  # get data for only max last 30 days 
  max = timeseries.high.length < DAYS_TO_TRACK ? (timeseries.high.length - 1) : DAYS_TO_TRACK
  count = 0
  CSV.open("data/#{old_sym}.csv", 'wb') do |csv|
    csv << ['Date', 'Close', 'High', 'Low', 'Change', 'CMP']
    for count in 0...max
      # Calculate the trend by comparing difference with closing price  
      close = ((timeseries.close[count][1].to_f - timeseries.close[count+1][1].to_f)/timeseries.close[count+1][1].to_f) * 100
      high = ((timeseries.high[count][1].to_f - timeseries.close[count+1][1].to_f)/timeseries.close[count+1][1].to_f) * 100
      low =  ((timeseries.low[count][1].to_f - timeseries.close[count+1][1].to_f)/timeseries.close[count+1][1].to_f) * 100
      csv << [timeseries.close[count][0], close, high, low, (high.abs + low.abs), timeseries.close[count][1]]
      high_trends << high if high > 0.0
      #p "----#{count}-----"
    end
  end
  high_trends.inject{ |sum, el| sum + el }.to_f / high_trends.size
end

#client = Alphavantage::Client.new key: '1OBOFRNE6KND478D'
#client.verbose = true

FileUtils.rm_rf("indicator_data/.", secure: true)
text=File.open('nse_fut_list.txt').read
text.gsub!(/\r\n?/, "\n")

sorted_list = {}
indicator_list = {}
text.each_line do |sym|
  sym.delete!("\n")
  old_sym = sym
  sym = 'NSE:' + sym
  timeseries = get_timeseries(sym)
  data = indicator(sym)
  indicator_data = calculate_indicator_trends(data, timeseries, old_sym) if data
  indicator_list[old_sym] = indicator_data if indicator_data
  if timeseries
    p timeseries.symbol
    avg = calculate_trends(timeseries, old_sym)
    sorted_list[old_sym] = avg unless avg.nan?
  else
    p "Failed to retrieve data"
  end
end
indicator_list = indicator_list.sort_by { |name, value| value }
p indicator_list.to_h.keys , "--------"

sorted_list = sorted_list.sort_by { |name, value| value }
p sorted_list.to_h.keys

