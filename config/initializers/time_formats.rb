Time::DATE_FORMATS[:ordinal] = lambda { |time| time.strftime("%Y %b #{time.day.ordinalize} %l%P") }
