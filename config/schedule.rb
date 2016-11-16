# 每年 1/1 00:05 init quota
every "5 0 1 1 *" do
  rake "leave_time:init"
end

# 每日 00:10 檢查 fulltime employee 是否獲得 8hr 特休
every "10 0 * * *" do
  rake "leave_time:refill"
end
