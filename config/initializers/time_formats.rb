Time::DATE_FORMATS[:year_date] = ->(time){ time.strftime("%Y-%m-%d") }
Time::DATE_FORMATS[:month_date] = ->(time){ time.strftime("%m/%d") }
Time::DATE_FORMATS[:ordinal] = lambda { |time| time.strftime("%Y %b #{time.day.ordinalize} %l%P") }
Time::DATE_FORMATS[:full] = ->(time){ time.strftime("%Y/%m/%d, %H:%M %p") }
