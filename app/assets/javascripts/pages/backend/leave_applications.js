document.addEventListener("turbolinks:load", function() {
  // 選擇假單狀態
  $leaveStatus = $("#status");
  $leaveStatus.on('change', function(e){
    value = $(this).val();
    switch(value) {
      case "approved":
        Turbolinks.visit("/backend/leave_applications?status=approved" );
        break;
      case "rejected":
        Turbolinks.visit("/backend/leave_applications?status=rejected" );
        break;
      case "canceled":
        Turbolinks.visit("/backend/leave_applications?status=canceled" );
        break;
      case "pending":
        Turbolinks.visit("/backend/leave_applications?status=pending" );
        break;
      default:
        Turbolinks.visit("/backend/leave_applications" );
    }
  })
})
