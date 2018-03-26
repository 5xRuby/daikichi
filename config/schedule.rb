# 每日 00:00 檢查是否初始化額度（Monthly and Join_date_base）
every "0 0 * * *" do
  rake "import:import"
end
