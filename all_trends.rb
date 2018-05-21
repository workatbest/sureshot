require 'alphavantagerb'
require 'csv'

DAYS_TO_TRACK=90
PERCENT_THRESHOLD=8.0

def get_timeseries(sym)
  for i in 0...5
    begin
      timeseries = Alphavantage::Timeseries.new symbol: sym, key: "1OBOFRNE6KND478D"
      break
    rescue Alphavantage::Error
      sleep(21)
      p 'retrying'
    end
  end
  timeseries
end

def calculate_trends(timeseries)
  high_trends=[]
  low_trends =[]
  close_trends = []
  timelines = []
  # get data for only ,ax last 30 days 
  max = timeseries.high.length < DAYS_TO_TRACK ? (timeseries.high.length - 1) : DAYS_TO_TRACK
  count = 0
  CSV.open("data/#{timeseries.symbol}.csv", 'wb') do |csv|
    csv << ['Date', 'Close', 'High', 'Low', 'Change']
    for count in 0...max
      #p timeseries.close[count+1]
      #p timeseries.close[count]
      #p timeseries.high[count]
      #p timeseries.low[count]
      #p "#{count} - #{timeseries.high[count]} - #{timeseries.low[count]}"
      # Calculate the trend by comparing difference with closing price  
      close = ((timeseries.close[count][1].to_f - timeseries.close[count+1][1].to_f)/timeseries.close[count+1][1].to_f) * 100
      high = ((timeseries.high[count][1].to_f - timeseries.close[count+1][1].to_f)/timeseries.close[count+1][1].to_f) * 100
      low =  ((timeseries.low[count][1].to_f - timeseries.close[count+1][1].to_f)/timeseries.close[count+1][1].to_f) * 100
      timelines << timeseries.close[count][1]
      #p (timeseries.low[count][1].to_f - timeseries.close[count-1][1].to_f)
      #p "close : #{close}, high : #{high}, low : #{low}, fluctuation : #{high.abs + low.abs}"
      csv << [timeseries.close[count][0], close, high, low, (high.abs + low.abs)]
      close_trends << close
      high_trends << high
      low_trends << low
      #p "----#{count}-----"
    end
  end
end

client = Alphavantage::Client.new key: '1OBOFRNE6KND478D'
#client.verbose = true

text=File.open('nse_fut_list.txt').read
text.gsub!(/\r\n?/, "\n")

text.each_line do |sym|
  sym.delete!("\n")
  old_sym = sym
  sym = 'NSE:' + sym
  timeseries = get_timeseries(sym)
  if timeseries
    p timeseries.symbol
    calculate_trends(timeseries)

  else
    p "Failed to retrieve data"
  end
end
