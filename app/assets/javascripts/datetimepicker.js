document.addEventListener('turbolinks:load', function() {
  var dateTimePicker = {
    $dateTimePickers: $("*[data-input='datetimepicker']"),

    initDateTimePickers: function(elem) {
      $(elem).flatpickr({
        defaultHour: 9,
        defaultMinute: 30,
        enableTime: true,
        dateFormat: $(elem).data('format'),
        time_24hr: true,
        minuteIncrement: 30
      });
    },

    init: function() {
      var $this = this;
      $this.$dateTimePickers.each(function() {
        $this.initDateTimePickers(this);
      });
    }
  }

  dateTimePicker.init();
});
