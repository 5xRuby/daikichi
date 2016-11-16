document.addEventListener("turbolinks:load", function() {
  //選擇年度
  $year = $("#year");
  $year.on('change', function(e){
    console.log(123);
    value = $(this).val();
    Turbolinks.visit("/leave_times?year=" + value );
  })
});
