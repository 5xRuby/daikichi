document.addEventListener("turbolinks:load", function() {

  var $year = $('select[id=year]')
  var $mon = $('select[id=mon]')

  $year.on('change', function() {
    Turbolinks.visit("/backend/employee_leave_times/" + $year.val() + "/" + $mon.val());
  });

  $mon.on('change', function() {
    Turbolinks.visit("/backend/employee_leave_times/" + $year.val() + "/" + $mon.val());

    // 做法一, 連至 /backend/employee_leave_times/year/mon, 整頁換掉
    //window.location.href = "/backend/employee_leave_times/" + $year.val() + "/" + $mon.val();


    // 做法二, ajax 打一樣的 action, 但送回 view 時，是一個 json 檔
    //$.get(
      //"/backend/employee_leave_times/" + x + "/" + mon.val() + ".json",
      //function(err, data) {
        //console.log(data, err)
      //}
    //)
  });
});
