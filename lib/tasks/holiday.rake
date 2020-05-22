# frozen_string_literal: true

namespace :holiday do
  desc 'Generate holiday data'
  task build: :environment do

    HOLIDAY_API = "https://data.ntpc.gov.tw/api/datasets/308DCD75-6434-45BC-A95F-584DA4FED251/json?page=0&size=9999"
    response = HTTParty.get(HOLIDAY_API)

    # 第一次會更新所有時間進去
    if Holiday.count == 0
      records = response.map do |record|
        Date.parse(record["date"])
      end.compact
    else
      last_day = Holiday.last.date.to_date
      records = response.map do |record|
        Date.parse(record["date"]) if Date.parse(record["date"]) > last_day
      end.compact
    end

    import_data = records.map{|record| {date: record}}
    result = Holiday.import import_data
    puts "Generate #{result[2].count} records"
  end
end
