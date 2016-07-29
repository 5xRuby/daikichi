$( function(){
  $('#datetimepicker_start').datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    daysOfWeekDisabled: [0, 6],
    enabledHours: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
    stepping: 30,
  });
  $('#datetimepicker_end').datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    daysOfWeekDisabled: [0, 6],
    enabledHours: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
    stepping: 30,
    defaultDate: moment(new Date).set({hour: 10, minute: 0})
  });
  $('#datetimepicker_start').on( 'dp.change', function(e){
    $('#datetimepicker_end').data('DateTimePicker').minDate( e.date.add(1, 'hours'));
  });
  $('#datetimepicker_end').on( 'dp.change', function(e){
    $('#datetimepicker_start').data('DateTimePicker').maxDate( e.date.subtract(1, 'hours'));
  });
});
