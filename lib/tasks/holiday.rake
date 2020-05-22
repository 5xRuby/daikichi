require 'yaml'

namespace :holiday do
  desc "build holiday data"
  task build: :environment do
    HOLIDAY_API = "https://data.ntpc.gov.tw/api/datasets/308DCD75-6434-45BC-A95F-584DA4FED251/json?page=0&size=9999"
    response = HTTParty.get(HOLIDAY_API)
    holidays = response.map { |record| Date.parse(record["date"]) }
    File.open("lib/tasks/holidays.yml", "w") { |file| file.write(holidays.to_yaml) }
  end
end
