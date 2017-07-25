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

  var $statistics_year  = $("select[id=year]")
  var $statistics_month = $("select[id=month]")

  $statistics_year.on('change', function() {
    Turbolinks.visit("/backend/leave_applications/statistics?year=" + $statistics_year.val() + "&month=" + $statistics_month.val());
  });

  $statistics_month.on('change', function() {
    Turbolinks.visit("/backend/leave_applications/statistics?year=" + $statistics_year.val() + "&month=" + $statistics_month.val());
  });

  // datetimepicker
  var $dateTimePickerStart = $('#datetimepicker_start');
  var $dateTimePickerEnd = $('#datetimepicker_end');

  $dateTimePickerStart.datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    disabledTimeIntervals: [[moment({ h: 0 }), moment({ h: 9, m: 29 })], [moment({ h: 18, m: 31 }), moment({ h: 24 })]],
    stepping: 30,
    useCurrent: false,
    sideBySide: true,
    viewDate: moment(new Date()).format('YYYY-MM-DD') + " 09:30",
  });

  $dateTimePickerEnd.datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    disabledTimeIntervals: [[moment({ h: 0 }), moment({ h: 9, m: 29 })], [moment({ h: 18, m: 31 }), moment({ h: 24 })]],
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
})
