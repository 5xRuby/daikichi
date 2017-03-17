
document.addEventListener("turbolinks:load", function() {
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
})
