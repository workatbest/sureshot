require 'alphavantagerb'
require 'nyaplot'
require 'gchart'

DAYS_TO_TRACK=30
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
  p timeseries
  timeseries
end

def calculate_trends(timeseries)
  high_trends=[]
  low_trends =[]
  close_trends = []
  timelines = []
  # get data for only ,ax last 30 days 
  max = timeseries.high.length < DAYS_TO_TRACK ? (timeseries.high.length - 1) : DAYS_TO_TRACK
  p timeseries.close[max]
  count = max - 1
  while(count > 0)
    p timeseries.close[count]
    p timeseries.high[count]
    p timeseries.low[count]
    #p "#{count} - #{timeseries.high[count]} - #{timeseries.low[count]}"
    # Calculate the trend by comparing difference with closing price  
    close = ((timeseries.close[count][1].to_f - timeseries.close[count-1][1].to_f)/timeseries.close[count-1][1].to_f) * 100
    high = ((timeseries.high[count][1].to_f - timeseries.close[count-1][1].to_f)/timeseries.close[count-1][1].to_f) * 100
    low =  ((timeseries.low[count][1].to_f - timeseries.close[count-1][1].to_f)/timeseries.close[count-1][1].to_f) * 100
    timelines << count
    p "close : #{close}, high : #{high}, low : #{low}"
    close_trends << close
    high_trends << high
    low_trends << low
    p "----#{count}-----"
    count -= 1
  end
  return close_trends, high_trends, low_trends, timelines
end

def add_trends(type, trends, timelines, plot)
  if trends.any? && (trends.max < PERCENT_THRESHOLD )
    #Difference Trend
    df = Nyaplot::DataFrame.new({x:timelines,y:trends})
    line = plot.add_with_df(df, :scatter, :x, :y)
    plot.x_label("Timeline")
    plot.y_label("Trend")
    plot.legend(true)
    line.title(type)
    line.color('#' + ("%06x" % (rand * 0xffffff)).to_s)
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
    close_trends, high_trends, low_trends, timelines = calculate_trends(timeseries)

    chart = Gchart.bar(data: [close_trends, high_trends, low_trends],legend:[ 'Close', 'High', 'Low'])
    p chart
    #plot1 = Nyaplot::Plot.new
    #df = Nyaplot::DataFrame.new({species: ['Persian', 'Maine Coon', 'American Shorthair'], number: [10,20,30]})
    #df = Nyaplot::DataFrame.new({x:timelines.reverse,y:close_trends.reverse})
    #plot1.add_with_df(df, :bar, :x, :y)


    #plot2 = Nyaplot::Plot.new
    #df = Nyaplot::DataFrame.new({x:timelines,y:high_trends})
    #plot2.add_with_df(df, :bar, :x, :y)

    #plot3 = Nyaplot::Plot.new
    #df = Nyaplot::DataFrame.new({x:timelines,y:low_trends})
    #plot3.add_with_df(df, :bar, :x, :y)

    #add_trends('Close', close_trends, timelines, plot)
    #add_trends('High', high_trends, timelines, plot)
    #add_trends('Low', low_trends, timelines, plot)

    #frame = Nyaplot::Frame.new
    #frame.add(plot1)
    #frame.add(plot2)
    #frame.add(plot3)
    #frame.show
    #plot1.export_html("graphs/#{old_sym}.html")
  else
    p "Failed to retrieve data"
  end
end
