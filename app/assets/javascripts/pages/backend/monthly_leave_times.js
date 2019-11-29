if($('body').data("controller-path") === "backend/monthly_leave_times"){
  document.addEventListener("turbolinks:load", function() {

    var $year = $("select[id=year]")
    var $month = $("select[id=month]")

    $year.on('change', function() {
      Turbolinks.visit("/backend/monthly_leave_times?year=" + $year.val() + "&month=" + $month.val());
    });

    $month.on('change', function() {
      Turbolinks.visit("/backend/monthly_leave_times?year=" + $year.val() + "&month=" + $month.val());
    });
  });
}