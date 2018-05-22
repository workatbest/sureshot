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

def calculate_trends(timeseries, old_sym)
  high_trends=[]
  # get data for only ,ax last 30 days 
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

client = Alphavantage::Client.new key: '1OBOFRNE6KND478D'
#client.verbose = true

text=File.open('nse_fut_list.txt').read
text.gsub!(/\r\n?/, "\n")

sorted_list = {}
text.each_line do |sym|
  sym.delete!("\n")
  old_sym = sym
  sym = 'NSE:' + sym
  timeseries = get_timeseries(sym)
  if timeseries
    p timeseries.symbol
    avg = calculate_trends(timeseries, old_sym)
    sorted_list[old_sym] = avg unless avg.nan?
  else
    p "Failed to retrieve data"
  end
end
p sorted_list
sorted_list = sorted_list.sort_by { |name, value| value }
p sorted_list.to_h.keys
