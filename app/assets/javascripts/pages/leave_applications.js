document.addEventListener("turbolinks:load", function() {
  // datetimepicker
  var $dateTimePickerStart = $('#datetimepicker_start');
  var $dateTimePickerEnd = $('#datetimepicker_end');

  $dateTimePickerStart.datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    enabledHours: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
    stepping: 30,
    useCurrent: false,
    sideBySide: true,
    viewDate: moment(new Date()).format('YYYY-MM-DD') + " 09:30",
  });

  $dateTimePickerEnd.datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    enabledHours: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
    stepping: 30,
    useCurrent: false,
    sideBySide: true,
    viewDate: moment(new Date()).format('YYYY-MM-DD') + " 10:30",
  });

  var startTimeChangeFirst = false;
  var $startTimeInput = $dateTimePickerStart.find("#leave_application_start_time");
  var $endTimeInput = $dateTimePickerEnd.find("#leave_application_end_time");

  $dateTimePickerStart.on( 'dp.change', function(e){
    if ( startTimeChangeFirst == false) {
      startTimeChangeFirst = true;
    }

    if (startTimeChangeFirst) {
      var startTime = moment( $startTimeInput.val() );
      var endTime = moment( $endTimeInput.val() );
      var m = startTime.clone().add(1, 'hours');

      $dateTimePickerEnd.data('DateTimePicker').minDate(m);

      if (startTime > endTime) {
        $dateTimePickerEnd.data('DateTimePicker').date(m);
      }
    }
  });

  $dateTimePickerEnd.on( 'dp.change', function(e){
    if (startTimeChangeFirst) {
      var endTime = moment( $endTimeInput.val() );
      var m = endTime.clone().subtract(1, 'hours');

      $dateTimePickerStart.data('DateTimePicker').maxDate( m );
    }
  });

  // 選擇假單狀態
  $leaveStatus = $("#status");
  $leaveStatus.on('change', function(e){
    value = $(this).val();
    switch(value) {
      case "approved":
        Turbolinks.visit("/leave_applications?status=approved" );
        break;
      case "rejected":
        Turbolinks.visit("/leave_applications?status=rejected" );
        break;
      case "canceled":
        Turbolinks.visit("/leave_applications?status=canceled" );
        break;
      default:
        Turbolinks.visit("/leave_applications?status=pending" );
    }
  })

  // ajax calling for personal 剩餘時數
  var form = $("form[class*='leave_application'].simple_form");
  var submit_button = form.find(".submit");

  form.submit( function(event){
    var leave_type_selection = document.getElementById("leave_application_leave_type");
    var leave_type  = leave_type_selection.options[leave_type_selection.selectedIndex].value;

    function click_hidden_button(){
      document.getElementsByClassName("btn_hidden leave_application")[0].click();
    };

    function retrieve_leave_time(){
      var text_area = $(".modal-body");

      $.ajax({
        url: "/leave_time/annual.json",
        dataType: "json",
        type: "GET",
        success: function(data, textStatus, jqXHR) {
          if (data.usable_hours > 0){
            text_area.text("您的特休還剩下: " + data.usable_hours + " 小時!!");
          } else{
            text_area.text("您已經沒有特休了QQ");
          }
        },
        error: function() {
          console.log("error");
        },
        complete: function(){
        }
      });
    };

    if (leave_type == "personal"){
      var yes_button = $(".modal-footer button.yes");
      var no_button = $(".modal-footer button.no");

      event.preventDefault();
      click_hidden_button();
      retrieve_leave_time();

      $(document).keyup(function(e){
        if (e.keyCode === 13) yes_button.click(); // enter
        if (e.keyCode === 27) no_button.click(); // esc
      });

      yes_button.on("click", function(){
        form.unbind("submit").submit();
      });

      no_button.on("click", function(){
        submit_button.prop("disabled", false);
      });
    } else {
      form.unbind("submit").submit();
    }
  })
});
