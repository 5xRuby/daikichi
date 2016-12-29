# Configure working hours
WorkingHours::Config.working_hours = {
  :mon => {'09:30' => '12:30', '13:30' => '18:30'},
  :tue => {'09:30' => '12:30', '13:30' => '18:30'},
  :wed => {'09:30' => '12:30', '13:30' => '18:30'},
  :thu => {'09:30' => '12:30', '13:30' => '18:30'},
  :fri => {'09:30' => '12:30', '13:30' => '18:30'}
}

# Configure timezone (uses activesupport, defaults to UTC)
WorkingHours::Config.time_zone = 'Taipei'
