document.addEventListener('turbolinks:load', function() {
  var datePicker = {
    $datePickers: $("*[data-input='datepicker']"),

    initDatePickers: function(elem) {
      $(elem).datetimepicker({
        format: $(elem).data('format'),
        sideBySide: true,
        stepping: 30,
        useCurrent: false,
        // TODO: disabledTimeIntervals should be changed according to business hours settings
        disabledTimeIntervals: [[moment({ h: 0 }), moment({ h: 9, m: 29 })], [moment({ h: 18, m: 31 }), moment({ h: 24 })]]
      });
    },

    init: function() {
      var $this = this;
      $this.$datePickers.each(function() {
        $this.initDatePickers(this);
      });
    }
  };

  datePicker.init();
});
