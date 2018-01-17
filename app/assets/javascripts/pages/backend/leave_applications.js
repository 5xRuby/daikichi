document.addEventListener("turbolinks:load", function() {
  $year = $("#year");
  $leaveStatus = $("#status");

  // 選擇假單狀態
  $leaveStatus.on('change', function(e){
    status = $(this).val();
    year = $year.val();
    Turbolinks.visit("/backend/leave_applications?status=" + status + "&year=" + year );
  })

  //選擇年度
  $year.on('change', function(e){
    year = $(this).val();
    status = $leaveStatus.val();
    Turbolinks.visit("/backend/leave_applications?status=" + status + "&year=" + year );
  })

  //員工休假統計頁
  var $statistics_year  = $("select[id=year]")
  var $statistics_month = $("select[id=month]")
  var $statistics_role = $("select[id=role]")

  $statistics_year.on('change', function() {
    Turbolinks.visit("/backend/leave_applications/statistics?year=" + $statistics_year.val() + "&month=" + $statistics_month.val());
  });

  $statistics_month.on('change', function() {
    Turbolinks.visit("/backend/leave_applications/statistics?year=" + $statistics_year.val() + "&month=" + $statistics_month.val());
  });

  $statistics_role.on("change", function() {
    Turbolinks.visit("/backend/leave_applications/statistics?year=" + $statistics_year.val() + "&month=" + $statistics_month.val() + "&role=" + $statistics_role.val());
  });
})
