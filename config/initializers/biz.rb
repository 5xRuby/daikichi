Biz.configure do |config|
  config.hours = {
    mon: {'09:30' => '12:30', '13:30' => '18:30'},
    tue: {'09:30' => '12:30', '13:30' => '18:30'},
    wed: {'09:30' => '12:30', '13:30' => '18:30'},
    thu: {'09:30' => '12:30', '13:30' => '18:30'},
    fri: {'09:30' => '12:30', '13:30' => '18:30'}
  }

  config.holidays = [Date.new(2016, 1, 1), Date.new(2016, 12, 25)]

  config.time_zone = 'Asia/Taipei'
end
