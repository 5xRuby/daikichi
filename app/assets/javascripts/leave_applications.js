$( function(){
  $('#datetimepicker_start').datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    enabledHours: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
    stepping: 30,
    useCurrent: false,
  });
  $('#datetimepicker_end').datetimepicker( {
    format: 'YYYY-MM-DD HH:mm',
    enabledHours: [9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
    stepping: 30,
    useCurrent: false,
  });
  $('#datetimepicker_start').on( 'dp.change', function(e){
    $('#datetimepicker_end').data('DateTimePicker').minDate( e.date.add(1, 'hours'));
    var m = moment(new Date(e.date))
    $('#datetimepicker_end').data('DateTimePicker').date(m);
  });
  $('#datetimepicker_end').on( 'dp.change', function(e){
    $('#datetimepicker_start').data('DateTimePicker').maxDate( e.date.subtract(1, 'hours'));
  });
});
