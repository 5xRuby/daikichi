document.addEventListener("turbolinks:load", function() {
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

  $('.status-selector > .pending').on('click', function(){
    Turbolinks.visit("/leave_applications/pending" );
  });

  $('.status-selector > .approved').on('click', function(){
    Turbolinks.visit("/leave_applications/approved" );
  });

  $('.status-selector > .rejected').on('click', function(){
    Turbolinks.visit("/leave_applications/rejected" );
  });

  $('.status-selector > .canceled').on('click', function(){
    Turbolinks.visit("/leave_applications/canceled" );
  });

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
            text_area.text("您的年假還剩下: " + data.usable_hours + " 小時\n此次請假會扣年假時數");
          } else{
            text_area.text("您已經沒有年假了QQ\n此次請假會扣事假時數");
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
