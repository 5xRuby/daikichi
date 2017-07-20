# 每年 10/1 00:05 初始化隔年休假額度
every '5 0 1 10 *' do
  rake "leave_time:init[Time.current.year + 1,'force']"
end

# 每日 00:10 檢查 fulltime employee 是否獲得 8hr 特休
every "10 0 * * *" do
  rake "leave_time:refill"
end
