if($('body').data("controller-path") === "leave_applications"){
  document.addEventListener("turbolinks:load", function() {
    $year = $("#year");
    $leaveStatus = $("#status");

    // 選擇假單狀態
    $leaveStatus.on('change', function(e){
      status = $(this).val();
      year = $year.val();
      Turbolinks.visit("/leave_applications?status=" + status + "&year=" + year );
    })

    //選擇年度
    $year.on('change', function(e){
      year = $(this).val();
      status = $leaveStatus.val();
      Turbolinks.visit("/leave_applications?status=" + status + "&year=" + year );
    })
  });
}