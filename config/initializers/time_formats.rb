Time::DATE_FORMATS[:ordinal] = lambda { |time| time.strftime("%Y %b #{time.day.ordinalize} %l%P") }
Time::DATE_FORMATS[:abbr] = ->(time){ time.strftime("%B %d, %H:%M %p") }
Time::DATE_FORMATS[:full] = ->(time){ time.strftime("%Y/%m/%d, %H:%M %p") }
